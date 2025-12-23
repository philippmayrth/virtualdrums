import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

extension CollisionGroup {
    static let drum = CollisionGroup(rawValue: 1 << 0)
    static let stickTipLeft = CollisionGroup(rawValue: 1 << 1)
    static let stickTipRight = CollisionGroup(rawValue: 1 << 2)
}

/// Runtime state for a single drum stick
/// (can be extended later with velocity, hit state, etc.)
struct StickState {
    var stickEntity: Entity
    var collidingEntity: Entity
}

private struct HitPair: Hashable {
    let stickID: ObjectIdentifier
    let drumName: String
}

private struct HitLock {
    let drumName: String
    let point: SIMD3<Float>
    let normal: SIMD3<Float>
}

struct StickConfig {
    static let handleLength: Float = 0.25
    static let handleRadius: Float = 0.005
    static let tipRadius: Float = 0.0075
}

struct ImmersiveView: View {
    @EnvironmentObject var appState: AppState
    @State var drumController = DrumController()
    @State private var leftStickState: StickState?
    @State private var rightStickState: StickState?
    @State private var updateSubscription: EventSubscription?
    @State var stickLastPosition: [ObjectIdentifier: SIMD3<Float>] = [:]
    @State private var activeHitPairs: Set<HitPair> = []
    @State private var hitLocks: [ObjectIdentifier: HitLock] = [:]
    @State private var rootDrumEntity = Entity()
#if targetEnvironment(simulator)
    @State var simulatorStickState: StickState?
    @State var simulatorStickPosition: SIMD3<Float> = SimulatorStickConfig.restPosition
    @State var simulatorSweepTask: Task<Void, Never>?
#endif // targetEnvironment(simulator)
    // TODO: refactor to use best practices for storing these properties (ViewModel? etc.)
    
    var body: some View {
        ZStack {
            RealityView { content in
                #if targetEnvironment(simulator)
                await setupSimulatorStick(content: content)
                #else
                await setupDrumSticks(content: content)
                #endif // targetEnvironment(simulator)
                
                await setupDrumSet(drumSet: appState.selectedDrumSet)
                content.add(rootDrumEntity)

                setupStickTracking(content: content)
            }
            #if targetEnvironment(simulator)
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        let local = value.location3D
                        let localPosition = SIMD3<Float>(Float(local.x), Float(local.y), Float(local.z))
                        let worldPosition = resolveTapWorldPosition(
                            entity: value.entity,
                            location: localPosition
                        )
                        handleDrumClick(entity: value.entity, worldPosition: worldPosition)
                    }
            )
            #endif // targetEnvironment(simulator)
        }
        .onChange(of: appState.selectedDrumSet, { oldSetID, newSetID in
            Task {
                await removeDrumSet(drumSet: oldSetID)
                activeHitPairs.removeAll()
                await setupDrumSet(drumSet: newSetID)
            }
        })
        .onChange(of: appState.keyboardKickTriggerToken, { _, _ in
            drumController.hitDrum(drum: .target_bass_drum)
        })
        .onChange(of: appState.keyboardHiHatTriggerToken, { _, _ in
            drumController.hitHiHat(isOpen: !appState.hiHatPedalIsClosed)
        })
        .onChange(of: appState.hiHatPedalIsClosed, { _, isClosed in
            if isClosed {
                drumController.closeHiHat()
            }
        })
        #if targetEnvironment(simulator)
        .onChange(of: appState.simulator.simulatorStickMoveToken, { _, _ in
            let delta = appState.simulator.simulatorStickMoveDelta
            moveSimulatorStick(dx: delta.x, dy: delta.y, dz: delta.z)
        })
        .onChange(of: appState.simulator.simulatorStickResetToken, { _, _ in
            resetSimulatorStick()
        })
        .onChange(of: appState.simulator.simulatorStickSweepToken, { _, _ in
            startSimulatorSweep(at: simulatorStickPosition)
        })
        #endif // targetEnvironment(simulator)
    }
    
    
    // MARK: Drum Set Entities
    
    @MainActor
    private func removeDrumSet(drumSet: DrumSetID) async {
        if let drumSetEntity = rootDrumEntity.children.first(where: { $0.name == drumSet.rawValue }) {
            drumSetEntity.removeFromParent()
        }
    }
    
    @MainActor
    private func setupDrumSet(drumSet: DrumSetID) async {
        let drumSetEntity: Entity
        do {
            drumSetEntity = try await Entity(named: drumSet.rawValue, in: .main)
        } catch {
            print("❌ Failed to load drum set model: \(error)")
            return
        }

        drumSetEntity.name = drumSet.rawValue
        drumSetEntity.position = [0, 0.15, -0.6] // Position the drum infront of the user
        
        await setupTargetsRecursively(from: drumSetEntity)
        
        rootDrumEntity.addChild(drumSetEntity)
    }
    
    private func setupTargetsRecursively(from entity: Entity) async {
        for child in entity.children {
            if let childEntity = child as? ModelEntity, // must be a ModelEntity (→ has a mesh)
               DrumID(rawValue: childEntity.name) != nil { // must be a recognized drum (→ named "target_[drum_piece]")
                await setupDrum(entity: childEntity)
            }
            
            await setupTargetsRecursively(from: child) // recurse into grandchildren, etc.
        }
    }
    
    private func setupDrum(entity: ModelEntity) async {
        var colliderShape: ShapeResource
        do {
            colliderShape = try await .generateConvex(from: entity.model!.mesh)
        } catch {
            print("⚠️ collider shape could not be generated from mesh. using box instead")
            return
        }
        
        entity.components.set(
            CollisionComponent(
                shapes: [colliderShape],
                filter: .init(group: .drum, mask: .stickTipLeft.union(.stickTipRight))
            )
        )
        #if targetEnvironment(simulator)
        entity.components.set(
            PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        )
        #endif // targetEnvironment(simulator)
        
        #if targetEnvironment(simulator)
        entity.components.set(InputTargetComponent())
        #endif // targetEnvironment(simulator)
        
        AudioEngine.shared.loadDrumSound(drum: DrumID(rawValue: entity.name)!)
        print ("✅ Drum piece set up: ", entity.name)
    }
    
    // MARK: Drum Sticks
    
    /// Creates both drum sticks
    @MainActor
    private func setupDrumSticks(content: RealityViewContent) async {
        self.leftStickState = setupStick(chirality: .left, content: content)
        self.rightStickState = setupStick(chirality: .right, content: content)
    }
    
    /// Creates a single stick and anchors it to the given hand.
    private func setupStick(chirality: AnchoringComponent.Target.Chirality, content: RealityViewContent) -> StickState {
        let (stickEntity, collidingEntity) = makeStick(chirality: chirality)
        let anchor: AnchorEntity = positionStickInHand(stick: stickEntity, chirality: chirality)
        content.add(anchor)
        return StickState(stickEntity: stickEntity, collidingEntity: collidingEntity)
    }
    
    /// Builds the full stick entity including handle, tip, and collision setup
    private func makeStick(chirality: AnchoringComponent.Target.Chirality) -> (Entity, Entity) {
        let tip = makeTipEntity(chirality: chirality)
        let handle = makeHandleEntity(chirality: chirality)
        let stickEntity = Entity()
        stickEntity.addChild(tip)
        stickEntity.addChild(handle)
        
        // Enables system input and collision event routing.
        // This also propagates to child entities that contain meshes.
        stickEntity.components.set(InputTargetComponent())
        
        // Promote the tip’s collision configuration to the root stick entity
        stickEntity.components.set(
            CollisionComponent(
                shapes: tip.collision!.shapes,
                filter: tip.collision!.filter
            )
        )

        return (stickEntity, tip)
    }
    
    private func makeHandleEntity(chirality: AnchoringComponent.Target.Chirality) -> ModelEntity {
        let handleMesh = MeshResource.generateCylinder(height: StickConfig.handleLength, radius: StickConfig.handleRadius)
        let handleMaterial = SimpleMaterial(color: .brown, isMetallic: false)
        let handleModel = ModelEntity(mesh: handleMesh, materials: [handleMaterial])
        
        handleModel.name = "stick_handle_\(chirality)"
        handleModel.position.y = StickConfig.handleLength / 2
        
        return handleModel
    }
    
    func makeTipEntity(chirality: AnchoringComponent.Target.Chirality) -> ModelEntity {
        let tipMesh = MeshResource.generateSphere(radius: StickConfig.tipRadius)
        let tipMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let tipModel = ModelEntity(mesh: tipMesh, materials: [tipMaterial])
        
        tipModel.name = "stick_tip_\(chirality)"
        tipModel.position.y = StickConfig.handleLength
        tipModel.scale.y = 1.2

        tipModel.components.set(
            CollisionComponent(
                shapes: [.generateSphere(radius: StickConfig.tipRadius)],
                // Only collides with entities in the "drum" collision group
                filter: .init(group: chirality == .left ? .stickTipLeft : .stickTipRight, mask: .drum)
            )
        )
        
        return tipModel
    }
    
    /// Positions and orients the stick to match a realistic hand grip,
    /// then anchors it to the user’s palm.
    func positionStickInHand(stick: Entity, chirality: AnchoringComponent.Target.Chirality) -> AnchorEntity {
        stick.position = [0, 0.025, -0.015] // Offset to approximate how a real drum stick is held
        let rotationX = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        let rotationZSign: Float = (chirality == .left) ? -1 : 1 // Mirror for left hand
        let rotationZ = simd_quatf(angle: rotationZSign * .pi / 2.2, axis: [0, 0, 1])
        stick.orientation = rotationX * rotationZ
        
        let anchor = AnchorEntity(
            .hand(chirality, location: .palm),
            trackingMode: .continuous,
            // !
            // Hand anchors use a separate physics simulation by default.
            // Disabling it ensures collisions are detected with entities anchored elsewhere (e.g., the drums).
            physicsSimulation: .none
        )
        
        anchor.addChild(stick)
        return anchor
    }

    private func setupStickTracking(content: RealityViewContent) {
        guard updateSubscription == nil else { return }

        updateSubscription = content.subscribe(to: SceneEvents.Update.self) { _ in
            var sticks = [
                leftStickState?.collidingEntity,
                rightStickState?.collidingEntity
            ].compactMap { $0 }
            #if targetEnvironment(simulator)
            if let simulatorStick = simulatorStickState?.collidingEntity {
                sticks.append(simulatorStick)
            }
            #endif // targetEnvironment(simulator)

            processRaycastHits(sticks: sticks)

            sticks.forEach { stick in
                stickLastPosition[ObjectIdentifier(stick)] = stick.position(relativeTo: nil)
            }
        }
    }

    private func processRaycastHits(sticks: [Entity]) {
        guard let scene = rootDrumEntity.scene else { return }
        let worldUp: SIMD3<Float> = [0, 1, 0]
        let normalThreshold: Float = 0.2
        let dirThreshold: Float = -0.1
        let releaseMargin: Float = StickConfig.tipRadius

        for stick in sticks {
            let stickID = ObjectIdentifier(stick)
            let current = stick.position(relativeTo: nil)
            let last = stickLastPosition[stickID] ?? current
            let delta = current - last
            let deltaLen = simd_length(delta)
            let dir = deltaLen == 0 ? SIMD3<Float>(0, 0, 0) : (delta / deltaLen)

            let hits = scene.raycast(from: last, to: current, query: .nearest, mask: .drum, relativeTo: nil)
            if let lock = hitLocks[stickID], let hit = hits.first {
                if hit.entity.name != lock.drumName {
                    hitLocks.removeValue(forKey: stickID)
                    activeHitPairs.remove(HitPair(stickID: stickID, drumName: lock.drumName))
                }
            }

            if let lock = hitLocks[stickID] {
                let normal = simd_length(lock.normal) == 0 ? SIMD3<Float>(0, 1, 0) : simd_normalize(lock.normal)
                let distance = simd_dot(current - lock.point, normal)

                if distance <= releaseMargin {
                    updateDebugHitCheck(
                        drumName: lock.drumName,
                        stickName: stick.name,
                        result: "blocked: inside"
                    )
                    continue
                }

                hitLocks.removeValue(forKey: stickID)
                activeHitPairs.remove(HitPair(stickID: stickID, drumName: lock.drumName))
            }

            if let hit = hits.first, DrumID(rawValue: hit.entity.name) != nil {
                updateDebugCollision(drumEntity: hit.entity, stickEntity: stick)

                if deltaLen == 0 {
                    updateDebugHitCheck(
                        drumName: hit.entity.name,
                        stickName: stick.name,
                        result: "rejected: no movement"
                    )
                } else {
                    let normalDot = simd_dot(hit.normal, worldUp)
                    let dirDot = simd_dot(dir, worldUp)

                    if normalDot > normalThreshold && dirDot < dirThreshold {
                        let hitPair = HitPair(stickID: stickID, drumName: hit.entity.name)
                        if !activeHitPairs.contains(hitPair) {
                            activeHitPairs.insert(hitPair)
                            let drumID = DrumID(rawValue: hit.entity.name)!
                            if drumID == .target_hi_hat {
                                drumController.hitHiHat(isOpen: !appState.hiHatPedalIsClosed)
                            } else {
                                drumController.hitDrum(drum: drumID)
                            }
                            updateDebugHitAccepted(drumName: hit.entity.name)
                        }
                        hitLocks[stickID] = HitLock(
                            drumName: hit.entity.name,
                            point: hit.position,
                            normal: hit.normal
                        )
                        updateDebugHitCheck(
                            drumName: hit.entity.name,
                            stickName: stick.name,
                            result: "hit accepted"
                        )
                    } else {
                        updateDebugHitCheck(
                            drumName: hit.entity.name,
                            stickName: stick.name,
                            result: normalDot <= normalThreshold ? "rejected: side hit" : "rejected: not moving down"
                        )
                    }
                }
            } else {
                updateDebugHitCheck(
                    drumName: "-",
                    stickName: stick.name,
                    result: "raycast miss"
                )
            }
        }
    }
    
}

// MARK: Preview

#Preview {
    ImmersiveView()
        .environmentObject(AppState())
}
