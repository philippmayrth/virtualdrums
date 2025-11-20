import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

struct DrumVolumeView: View {
    @EnvironmentObject var appState: AppState
    @State private var drumController: DrumController?
    @State private var message: String = "Touch a drum to play!"
    @State private var isSetup = false
    
    var body: some View {
        ZStack {
            RealityView { content in
                if !isSetup {
                    setupController()
                    isSetup = true
                }
                await setupDrumKit(content: content)
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
    }
    
    private func setupController() {
        let selectedKit = DrumKit.kit(named: appState.selectedDrumKitName)
        let controller = DrumController(drumKit: selectedKit, maxPolyphony: 8)
        controller.setup()
        self.drumController = controller
        print("🎵 Loaded drum kit: \(selectedKit.name)")
    }
    
    private func setupDrumKit(content: RealityViewContent) async {
        guard let controller = drumController else { return }
        
        let kitAnchor = AnchorEntity(world: [0, -0.3, -0.5])
        
        do {
            let drumKitEntity = try await Entity(named: "DrumKit_Named", in: .main)
            drumKitEntity.scale = [0.01, 0.01, 0.01]
            drumKitEntity.position = [0, 0, 0]
            
            print("📦 Loaded DrumKit_Named model")
            
            configureDrumParts(entity: drumKitEntity)
            drumKitEntity.generateCollisionShapes(recursive: true)
            kitAnchor.addChild(drumKitEntity)
            content.add(kitAnchor)
            
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
            "TomTom_Skin": "tom1",       // Only one tom in the model - maps to tom1
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
}

#Preview {
    DrumVolumeView()
        .environmentObject(AppState())
}
