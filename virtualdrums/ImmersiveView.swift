import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation
import ARKit

extension CollisionGroup {
    static let drum = CollisionGroup(rawValue: 1 << 0)
    static let stickTipLeft = CollisionGroup(rawValue: 1 << 1)
    static let stickTipRight = CollisionGroup(rawValue: 1 << 2)
}

struct StickState {
    let stickEntity: Entity
    let tipEntity: Entity
    var lastTipPosition: SIMD3<Float>?
    var isInsideDrum: Bool = false // Prevents multiple hits while inside the drum
}

struct StickConfig {
    static let handleLength: Float = 0.25
    static let handleRadius: Float = 0.004
    static let tipRadius: Float = 0.005
}

struct ImmersiveView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pedals = FootPedalManager.shared
    @StateObject private var drumController = DrumController.shared
    @StateObject private var grip = HandGripManager.shared
    @State private var leftStick: StickState?
    @State private var rightStick: StickState?
    @State private var handTrackingSession = ARKitSession()
    @State private var handProvider = HandTrackingProvider()    
    @State private var updateSub: EventSubscription?
    @State private var rootDrumEntity = Entity()
    @State private var hiHatTopEntity: ModelEntity?
    @State private var hiHatRestPosition: SIMD3<Float> = .zero
    @State private var bassDrumPedalEntity: ModelEntity?
    @State private var bassDrumPedalRestPosition: SIMD3<Float> = .zero
    @State private var drumRestOrientations: [Entity.ID: simd_quatf] = [:]

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

                await setupUpdateLoop(content: content)
            }
            #if !targetEnvironment(simulator)
            .task {
                try? await handTrackingSession.run([handProvider])
            }
            .task {
                for await update in handProvider.anchorUpdates {
                    HandGripManager.shared.update(from: update.anchor)
                }
            }
            #endif // !targetEnvironment(simulator)
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        // Toggle hi-hat closed/open state
                        if (value.entity.name == DrumID.target_hi_hat_top.rawValue) {
                            pedals.toggleHiHat()
                        }
                        
                        #if targetEnvironment(simulator)
                        // Trigger drum hit
                        guard let drumId = DrumID(rawValue: value.entity.name) else { return }
                        drumController.hitDrum(drum: drumId, strikeSpeed: nil)
                        
                        // Start simulator sweep test at tap position
                        let local = value.location3D
                        let localPosition = SIMD3<Float>(Float(local.x), Float(local.y), Float(local.z))
                        let worldPosition = resolveTapWorldPosition( entity: value.entity, location: localPosition )
                        startSimulatorSweep(at: worldPosition)

                        // TODO: calculate correct world position
                        wiggleDrum(drum: value.entity, hitWorldPosition: worldPosition, strikeSpeed: 3.0)                             

                        #endif // targetEnvironment(simulator)
                    }
            )
        }
        .onChange(of: appState.selectedDrumSet, { oldSetID, newSetID in
            Task {
                await removeDrumSet(drumSet: oldSetID)
                await setupDrumSet(drumSet: newSetID)
            }
        })
        .onChange(of: pedals.hiHatPedalDistance, {_, newDistance in
            updateHiHatPosition(distance: newDistance)
        })
        .onChange(of: pedals.kickPedalDistance, {_, newDistance in
            updateBassDrumPosition(distance: newDistance)
        })
        .onChange(of: pedals.isControllerConnected, {_, isConnected in
            bassDrumPedalEntity?.isEnabled = isConnected 
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
            if let childEntity = child as? ModelEntity { // must be a ModelEntity (→ has a mesh)
                
                if DrumID(rawValue: childEntity.name) != nil { // must be a recognized drum (→ named "target_[drum_piece]")
                    await setupDrum(entity: childEntity)
                    
                    if (entity.name == DrumID.target_hi_hat_top.rawValue) { // setup extra config for hi hat
                        setupHiHat(entity: childEntity)
                    }
                }
                else if childEntity.name == "bass_drum_pedal" {
                    setupBassDrumPedal(entity: childEntity)
                }
                
            }
            await setupTargetsRecursively(from: child) // recurse into grandchildren, etc.
        }
    }
    
    private func setupDrum(entity: ModelEntity) async {
        var colliderShape: ShapeResource
        do {
            colliderShape = try await .generateConvex(from: entity.model!.mesh)
        } catch {
            print("⚠️ collider shape could not be generated from mesh!")
            return
        }
        
        entity.components.set(
            CollisionComponent(
                shapes: [colliderShape],
                filter: .init(group: .drum, mask: .stickTipLeft.union(.stickTipRight))
            )
        )
        
        drumRestOrientations[entity.id] = entity.orientation
        
        #if targetEnvironment(simulator)
        entity.components.set(InputTargetComponent())
        #endif // targetEnvironment(simulator)
        
        drumController.loadDrum(drum: DrumID(rawValue: entity.name)!)
        print ("✅ Drum piece set up: ", entity.name)
    }
    
    private func setupHiHat(entity: ModelEntity) {
        self.hiHatTopEntity = entity
        self.hiHatRestPosition = entity.position
        entity.components.set(InputTargetComponent())
        let maxLift: Float = appState.selectedDrumSet == .burgundy_drum ? 0.07 : 4
        hiHatTopEntity?.position = hiHatRestPosition + SIMD3<Float>(0, 0, pedals.hiHatPedalDistance * maxLift)
    }
    
    private func updateHiHatPosition(distance: Float) {
        // drum models have different scale, therefore we use a easy fix and hard code different values
        let maxLift: Float = appState.selectedDrumSet == .burgundy_drum ? 0.07 : 4
        
        if (pedals.isControllerConnected) {
            hiHatTopEntity?.position = hiHatRestPosition + SIMD3<Float>(0, 0, distance * maxLift)
        } else { // with animation
            hiHatTopEntity?.move(to: Transform(translation: hiHatRestPosition + SIMD3<Float>(0, 0, distance * maxLift)),
                relativeTo: hiHatTopEntity?.parent,
                duration: 0.25
            )
        }
    }
    
    private func setupBassDrumPedal(entity: ModelEntity) {
        self.bassDrumPedalEntity = entity
        self.bassDrumPedalRestPosition = entity.position
        self.bassDrumPedalEntity?.isEnabled = false
        updateBassDrumPosition(distance: pedals.kickPedalDistance)
    }
    
    private func updateBassDrumPosition(distance: Float) {
        bassDrumPedalEntity?.position = bassDrumPedalRestPosition + SIMD3<Float>(0, -1 * distance * 10, 0)
    }
    
    // MARK: Drum Sticks
    
    /// Creates both drum sticks
    @MainActor
    private func setupDrumSticks(content: RealityViewContent) async {
        self.leftStick = setupStick(chirality: .left, content: content)
        self.rightStick = setupStick(chirality: .right, content: content)
    }
    
    /// Creates a single stick and anchors it to the given hand.
    private func setupStick(chirality: AnchoringComponent.Target.Chirality, content: RealityViewContent) -> StickState {
        let tip = makeStickTip(chirality: chirality)
        let handle = makeStickHandle(chirality: chirality)
        let stick = Entity()
        stick.addChild(tip)
        stick.addChild(handle)
        
        // Needed for Collision Detection and Raycasting.
        // This also propagates to child entities that contain meshes.
        stick.components.set(InputTargetComponent())
        
        // Promote the tip’s collision configuration to the root stick entity
        stick.components.set(
            CollisionComponent(
                shapes: tip.collision!.shapes,
                filter: tip.collision!.filter
            )
        )

        let anchor: AnchorEntity = positionStickInHand(stick: stick, chirality: chirality)
        content.add(anchor)

        return StickState(stickEntity: stick, tipEntity: tip)
    }

    private func makeStickHandle(chirality: AnchoringComponent.Target.Chirality) -> ModelEntity {
        let mesh = MeshResource.generateCylinder(height: StickConfig.handleLength, radius: StickConfig.handleRadius)
        let material = SimpleMaterial(color: .brown, isMetallic: false)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position.y = StickConfig.handleLength / 2
        return model
    }

    func makeStickTip(chirality: AnchoringComponent.Target.Chirality) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: StickConfig.tipRadius)
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position.y = StickConfig.handleLength
        model.scale.y = 1.2
        
        model.components.set(
            CollisionComponent(
                shapes: [.generateSphere(radius: StickConfig.tipRadius)],
                // Only collides with entities in the "drum" collision group
                filter: .init(group: chirality == .left ? .stickTipLeft : .stickTipRight, mask: .drum)
            )
        )
        
        return model
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

    // MARK: Update Loop + Raycasting

    private func setupUpdateLoop(content: RealityViewContent) async {
        updateSub = content.subscribe(to: SceneEvents.Update.self) { event in
            updateStickVisibility()

            processStrike(stick: &leftStick, deltaTime: Float(event.deltaTime))
            processStrike(stick: &rightStick, deltaTime: Float(event.deltaTime))
            
            #if targetEnvironment(simulator)
            processStrike(stick: &simulatorStickState, deltaTime: Float(event.deltaTime))
            #endif // targetEnvironment(simulator)
        }
    }
    
    /// Shows or hides the drum sticks based on whether the user is gripping, matching real-world playing intent and reducing accidental interaction.
    /// Stick visibility is also tied to grip state because collision and raycast detection are strangely only reliable when the hand is in a fist.
    private func updateStickVisibility() {
        leftStick?.stickEntity.isEnabled = grip.isLeftHandGripping
        rightStick?.stickEntity.isEnabled = grip.isRightHandGripping
    }

    private func processStrike(stick: inout StickState?, deltaTime: Float ) {
        guard var s = stick else { return }
        guard s.stickEntity.isEnabled else { return } // only process if stick is visible (hand is gripping)

        let tipPosition = s.tipEntity.position(relativeTo: nil)
        guard let lastPosition = s.lastTipPosition else {
            // no lastPosition = first update loop → set current position as last and return
            s.lastTipPosition = tipPosition
            stick = s
            return
        }

        let strikeVelocity: SIMD3<Float> = (tipPosition - lastPosition) / deltaTime
        let strikeSpeed: Float = simd_length(strikeVelocity)
        let strikeDirection = normalize(tipPosition - lastPosition)
        let strikeDistance = distance(tipPosition, lastPosition)

        let minSpeed: Float = 0.3
        if (strikeSpeed < minSpeed) {
            return
        }

        guard let scene = stick?.tipEntity.scene else { return }
        let hits = scene.raycast(
            origin: lastPosition,
            direction: strikeDirection,
            length: strikeDistance,
            query: .nearest,
            mask: .drum,
        )

        processRaycastHits(s: &s, hits: hits, strikeSpeed: strikeSpeed)

        s.lastTipPosition = tipPosition
        stick = s
    }

    private func processRaycastHits(s: inout StickState, hits: [CollisionCastHit], strikeSpeed: Float) {
        if let hit = hits.first {

            #if targetEnvironment(simulator)
            updateDebugCollision(drumEntity: hit.entity, stickEntity: s.stickEntity)
            #endif // targetEnvironment(simulator)

            // Get the entity UP vector (direction of the drum surface)
            let transform = hit.entity.transformMatrix(relativeTo: nil)
            let entityUp = normalize(SIMD3<Float>(
                transform.columns.2.x,
                transform.columns.2.y,
                transform.columns.2.z
            ))

            // Checks if the strike was directed at the top (drum) surface (≈ within 45° of up)
            let isTopHit = dot(hit.normal, entityUp) > 0.7
            if isTopHit && !s.isInsideDrum,
               let drumId = DrumID(rawValue: hit.entity.name) {
                // stick hit against the up/drum side --> mark stick as inside and play sound
                s.isInsideDrum = true
                drumController.hitDrum(drum: drumId, strikeSpeed: strikeSpeed)
                wiggleDrum(drum: hit.entity, hitWorldPosition: hit.position, strikeSpeed: strikeSpeed)
                
                #if targetEnvironment(simulator)
                updateDebugHitAccepted(drumName: hit.entity.name)
                #endif // targetEnvironment(simulator)
            } else {
                // stick hit a drum, but not against the up/drum side --> mark stick as inside the drum, to not trigger false hits
                s.isInsideDrum = true

                #if targetEnvironment(simulator)
                updateDebugHitCheck(drumName: hit.entity.name, stickName: s.stickEntity.name, result: "hit rejected (not top hit or already inside)")
                #endif // targetEnvironment(simulator)
            }
        } else {
            // no hits detected --> mark stick as outside the drum, to enable new hits
            s.isInsideDrum = false
        }
    }
    
    @MainActor
    private func wiggleDrum(
        drum: Entity,
        hitWorldPosition: SIMD3<Float>,
        strikeSpeed: Float
    ) {
        guard let restOrientation = drumRestOrientations[drum.id] else { return }

        let center = drum.position(relativeTo: nil)
        let rawHitDir = hitWorldPosition - center
        
        // Get the entity UP vector (direction of the drum surface)
        let transform = drum.transformMatrix(relativeTo: nil)
        let drumNormal = normalize(SIMD3<Float>(
            transform.columns.2.x,
            transform.columns.2.y,
            transform.columns.2.z
        ))

        // Hit direction → tilt axis
        let hitDirInPlane = rawHitDir - dot(rawHitDir, drumNormal) * drumNormal
        guard simd_length_squared(hitDirInPlane) > 0.0001 else { return }
        let hitDir = normalize(hitDirInPlane)
        let worldTiltAxis = normalize(cross(drumNormal, hitDir))
        let localTiltAxis = normalize(
            drum.convert(direction: worldTiltAxis, from: nil)
        )
       
        // Hit radius (distance from center)
        let hitRadius = simd_length(hitDirInPlane)

        // Tuned drum radius (world units)
        
        let bounds = drum.visualBounds(relativeTo: nil)
        let radius = max(bounds.extents.x, bounds.extents.z) * 0.5
        
        // Radius factor (0.0 - 1.0), influences tilt angle
        let radiusFactor = min(hitRadius / radius, 1.0)

        // strikeSpeed → angle
        let clampedSpeed: Float = min(max(strikeSpeed, 0.2), 6.0)

        // Hi-hat pedal dampening
        let isHiHatTop = drum.name == DrumID.target_hi_hat_top.rawValue
        let hiHatFactor: Float? = isHiHatTop ? max(0.03, pedals.hiHatPedalDistance) : nil

        let angle = clampedSpeed * 0.05 * radiusFactor * (hiHatFactor ?? 1.0)


        let tilt = simd_quatf(angle: angle, axis: localTiltAxis)

        drum.move(
            to: Transform(
                scale: drum.scale,
                rotation: tilt * restOrientation,
                translation: drum.position
            ),
            relativeTo: drum.parent,
            duration: 0.05,
            timingFunction: .easeOut
        )

        drum.move(
            to: Transform(
                scale: drum.scale,
                rotation: restOrientation,
                translation: drum.position
            ),
            relativeTo: drum.parent,
            duration: 0.3,
            timingFunction: .easeInOut
        )
    }

}

// MARK: Preview

#Preview {
    ImmersiveView()
        .environmentObject(AppState())
}
