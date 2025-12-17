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

struct DrumVolumeView: View {
    @EnvironmentObject var appState: AppState
    @State private var drumController = DrumController()
    @State private var leftStickState: StickState?
    @State private var rightStickState: StickState?
    @State private var collisionsOfLeftStick: EventSubscription?
    @State private var collisionsOfRightStick: EventSubscription?
    
    var body: some View {
        ZStack {
            RealityView { content in

                await setupDrumSticks(content: content)
                await setupDrumKit(content: content)
                await setupCollisions(content: content)
            }
            //            .gesture(
            //                SpatialTapGesture()
            //                    .targetedToAnyEntity()
            //                    .onEnded { value in
            //                        handleDrumTap(entity: value.entity)
            //                    }
            //            )
        }
    }
    
    
    // MARK: Drum Entities
    
    @MainActor
    private func setupDrumKit(content: RealityViewContent) async {
        let drumKitEntity: Entity
        do {
            drumKitEntity = try await Entity(named: "burgundy_drum", in: .main)
        } catch {
            print("Failed to load drum kit model: \(error)")
            return
        }
        
        drumKitEntity.position = [0, 0.15, -0.6] // Position the drum infront of the user
        
        await setupTargetsRecursively(from: drumKitEntity)
        
        content.add(drumKitEntity)
        print("🥁 Drum kit setup complete!")
    }
    
    private func setupTargetsRecursively(from entity: Entity) async {
        for child in entity.children {
            if let model = child as? ModelEntity,
               model.name.starts(with: "target_"){
                await setupDrum(drum: model)
            }
            
            await setupTargetsRecursively(from: child) // recurse into grandchildren, etc.
        }
    }
    
    private func setupDrum(drum: ModelEntity) async {
        var colliderShape: ShapeResource
        do {
            colliderShape = try await .generateConvex(from: drum.model!.mesh)
        } catch {
            print("collider shape could not be generated from mesh. using box instead")
            return
        }
        
        drum.components.set(
            CollisionComponent(
                shapes: [colliderShape],
                filter: .init(group: .drum, mask: .stickTipLeft.union(.stickTipRight))
            )
        )
        
        AudioEngine.shared.loadDrumSound(drumName: drum.name)
        print ("Drum set up: ", drum.name)
    }

    @MainActor
    private func addMockDrum(content: RealityViewContent) async {
        let mesh = MeshResource.generateBox(size: 0.5)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let drum = ModelEntity(mesh: mesh, materials: [material])
        drum.name = "MockDrum"
        drum.position = [0, 1, -1]
        drum.generateCollisionShapes(recursive: false)
        drum.components.set(
            CollisionComponent(
                shapes: drum.collision!.shapes,
                filter: .init(group: .drum, mask: .stickTipLeft.union(.stickTipRight))
            )
        )
        content.add(drum)
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
    
    // MARK: Collision Detection
    
    private func setupCollisions(content: RealityViewContent) async {
        self.collisionsOfLeftStick = content.subscribe(
            to: CollisionEvents.Began.self,
            on: leftStickState?.collidingEntity
        ) { event in handleCollision(event: event) }

        self.collisionsOfRightStick = content.subscribe(
            to: CollisionEvents.Began.self,
            on: rightStickState?.collidingEntity
        ) { event in self.handleCollision(event: event) }
    }
    
    private func handleCollision(event: CollisionEvents.Began) {
        let name = event.entityB.name
         print("Collision with:", name)
        
        if (name.hasPrefix("target_")) {
            drumController.hitDrum(drum: name)
        }
    }
    
/// Method that hitting drums via click gesture (used for Simulator)
//    private func handleDrumTap(entity: Entity) {
//        guard let controller = drumController else { return }
//
//        var currentEntity: Entity? = entity
//        var drumId: String? = nil
//
//        while currentEntity != nil && drumId == nil {
//            drumId = controller.getDrumIdFromEntity(name: currentEntity!.name)
//            currentEntity = currentEntity?.parent
//        }
//
//        if let drumId = drumId {
//            let velocity: Float = Float.random(in: 0.7...1.0)
//            controller.hitDrum(id: drumId, velocity: velocity)
//
//            if let piece = controller.getDrumPiece(id: drumId) {
//                message = "🥁 \(piece.name) played!"
//            }
//
//            print("🎵 \(drumId) - velocity: \(velocity)")
//        } else {
//            message = "Tapped: \(entity.name)"
//            print("⚠️ Unknown: \(entity.name)")
//        }
//    }
    
}

// MARK: Preview

#Preview {
    DrumVolumeView()
        .environmentObject(AppState())
}
