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
    @State private var drumController: DrumController?
    @State private var message: String = "Touch a drum to play!"
    @State private var isSetup = false
    @State private var leftStickState: StickState?
    @State private var rightStickState: StickState?
    @State private var collisionsOfLeftStick: EventSubscription?
    @State private var collisionsOfRightStick: EventSubscription?
    
    var body: some View {
        ZStack {
            RealityView { content in
                if !isSetup {
                    setupController()
                    isSetup = true
                }

                await setupDrumSticks(content: content)
                await setupDrumKit(content: content)
                await addMockDrum(content: content)
                await setupCollisionSubscriptions(content: content)
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        handleDrumTap(entity: value.entity)
                    }
            )
            .ignoresSafeArea()
        }
        .overlay(
            VStack {
                Text(message)
                    .font(.title2)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                if let controller = drumController, controller.hitCount > 0 {
                    Text("Hits: \(controller.hitCount)")
                        .font(.caption)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if let controller = drumController, !controller.audioEngine.failedSounds.isEmpty {
                    Text("⚠️ Missing: \(controller.audioEngine.failedSounds.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if let controller = drumController {
                    Text("Kit: \(controller.drumKit.name)")
                        .font(.caption)
                        .padding(4)
                        .background(.blue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(),
            alignment: .top
        )
        .onChange(of: appState.selectedDrumKitName) { _, newKitName in
            changeDrumKit(to: newKitName)
        }
    }
    
    private func setupController() {
        let selectedKit = DrumKit.kit(named: appState.selectedDrumKitName)
        let controller = DrumController(drumKit: selectedKit, maxPolyphony: 8)
        controller.setup()
        self.drumController = controller
        print("🎵 Loaded drum kit: \(selectedKit.name)")
    }
    
    private func setupDrumKit(content: RealityViewContent) async {
        guard drumController != nil else { return }
                    
        do {
            // 1. Create floor plana anchor
            let floorAnchor = AnchorEntity(
                .plane(
                    .horizontal,
                    classification: .floor,
                    minimumBounds: [1, 1]  // TODO: adjust depending on final model size
                ),
                trackingMode: .continuous,
                physicsSimulation: .none
            )
                
            // 2. Load the drum kit model
            let drumKitEntity = try await Entity(named: "DrumKit_Named", in: .main)
            drumKitEntity.scale = [0.01, 0.01, 0.01]
            drumKitEntity.position = [0, 0, 0]
            drumKitEntity.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0]) // Faces the kit towards the user
            
            // 3. Configure input & collisions for individual drums
            configureDrumParts(entity: drumKitEntity)
            drumKitEntity.generateCollisionShapes(recursive: true)
                        
            // 4. Add the kit to the floor anchor and anchor to the scene
            floorAnchor.addChild(drumKitEntity)
            content.add(floorAnchor)
            
            print("🥁 Drum kit setup complete!")
        } catch {
            print("❌ Failed to load DrumKit_Named model: \(error)")
        }
    }
    
    private func configureDrumParts(entity: Entity) {
        // Map ALL drum entity names to drum IDs - now includes all 8 drums!
        let drumMapping: [String: String] = [
            "Snare_Skin": "snare",
            "Bass_Outer_Skin": "kick",
            "TomTom_Skin": "tom1",        // Only one tom in the model - maps to tom1
            "Cymbol": "crash",            // Cymbal misspelled in model - maps to crash
            "Hi": "hihat",                // For any Hi-Hat variations
            // Note: The ugly model only has 1 tom and 1 cymbal
            // tom2, tom3, ride won't be found in the model, so they won't be configured
            // But the sounds will still be loaded and can be triggered programmatically
        ]
        
        searchAndConfigureEntities(entity, drumMapping: drumMapping, depth: 0)
    }
    
    private func searchAndConfigureEntities(_ entity: Entity, drumMapping: [String: String], depth: Int) {
        let entityName = entity.name
        
        for (pattern, drumId) in drumMapping {
            if entityName.contains(pattern) {
                entity.components.set(InputTargetComponent())
                if !entity.name.contains("_DRUM_") {
                    entity.name = "\(entity.name)_DRUM_\(drumId)"
                    print("✅ Configured: \(pattern) → \(drumId)")
                }
                break
            }
        }
        
        for child in entity.children {
            searchAndConfigureEntities(child, drumMapping: drumMapping, depth: depth + 1)
        }
    }
    
    private func changeDrumKit(to kitName: String) {
        guard let controller = drumController else {
            setupController()
            return
        }
        
        let newKit = DrumKit.kit(named: kitName)
        controller.drumKit = newKit
        controller.setup()
        
        message = "Switched to \(kitName)"
        print("Switched drum kit to \(kitName)")
    }
    
    private func handleDrumTap(entity: Entity) {
        guard let controller = drumController else { return }
        
        var currentEntity: Entity? = entity
        var drumId: String? = nil
        
        while currentEntity != nil && drumId == nil {
            drumId = controller.getDrumIdFromEntity(name: currentEntity!.name)
            currentEntity = currentEntity?.parent
        }
        
        if let drumId = drumId {
            let velocity: Float = Float.random(in: 0.7...1.0)
            controller.hitDrum(id: drumId, velocity: velocity)
            
            if let piece = controller.getDrumPiece(id: drumId) {
                message = "🥁 \(piece.name) played!"
            }
            
            print("🎵 \(drumId) - velocity: \(velocity)")
        } else {
            message = "Tapped: \(entity.name)"
            print("⚠️ Unknown: \(entity.name)")
        }
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
    
    private func setupCollisionSubscriptions(content: RealityViewContent) async {
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
        print("Collision with: ", event.entityB.name)
    }
}

// MARK: Preview

#Preview {
    DrumVolumeView()
        .environmentObject(AppState())
}
