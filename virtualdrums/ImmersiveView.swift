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
    var collidingEntity: EventSource
}

struct StickConfig {
    static let handleLength: Float = 0.25
    static let handleRadius: Float = 0.005
    static let tipRadius: Float = 0.0075
}

struct ImmersiveView: View {
    @EnvironmentObject var appState: AppState
    @State private var drumController = DrumController()
    @State private var leftStick: StickState?
    @State private var rightStick: StickState?
    @State private var collisionSubscriptions: [EventSubscription] = []
    @State private var rootDrumEntity = Entity()
    // TODO: refactor to use best practices for storing these properties (ViewModel? etc.)
    
    var body: some View {
        ZStack {
            RealityView { content in
                #if !targetEnvironment(simulator)
                await setupDrumSticks(content: content)
                #endif // !targetEnvironment(simulator)
                
                await setupDrumSet(drumSet: appState.selectedDrumSet)
                content.add(rootDrumEntity)

                await setupCollisions(content: content)
            }
            #if targetEnvironment(simulator)
            // add a click-to-hit gesture for the simulator
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        if let drumId = DrumID(rawValue: value.entity.name) {
                            drumController.hitDrum(drum: drumId)
                        }
                    }
            )
            #endif // targetEnvironment(simulator)
        }
        .onChange(of: appState.selectedDrumSet, { oldSetID, newSetID in
            Task {
                await removeDrumSet(drumSet: oldSetID)
                await setupDrumSet(drumSet: newSetID)
            }
        })
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
            print("⚠️ collider shape could not be generated from mesh!")
            return
        }
        
        entity.components.set(
            CollisionComponent(
                shapes: [colliderShape],
                filter: .init(group: .drum, mask: .stickTipLeft.union(.stickTipRight))
            )
        )
        
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

        return StickState(stickEntity: stick, collidingEntity: tip)
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

    // MARK: Collision Detection

    private func setupCollisions(content: RealityViewContent) async {
        [leftStick?.collidingEntity, rightStick?.collidingEntity]
            .compactMap{ $0 }
            .forEach { stick in
                let sub = content.subscribe(
                    to: CollisionEvents.Began.self,
                    on: stick
                ) { event in handleCollision(event: event) }

                collisionSubscriptions.append(sub)
            }
    }
    
    private func handleCollision(event: CollisionEvents.Began) {
        let name = event.entityB.name
         print("Collision with:", name)
        
        if let drumId = DrumID(rawValue: name) {
            drumController.hitDrum(drum: drumId)
        }
    }
    
}

// MARK: Preview

#Preview {
    ImmersiveView()
        .environmentObject(AppState())
}
