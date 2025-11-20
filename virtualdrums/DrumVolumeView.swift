import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

struct DrumVolumeView: View {
    @StateObject private var drumController = DrumController(drumKit: .standard, maxPolyphony: 8)
    @State private var message: String = "Touch a drum to play!"
    
    var body: some View {
        ZStack {
            RealityView { content in
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
                
                if drumController.hitCount > 0 {
                    Text("Hits: \(drumController.hitCount)")
                        .font(.caption)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Debug info
                if !drumController.audioEngine.failedSounds.isEmpty {
                    Text("⚠️ Missing sounds: \(drumController.audioEngine.failedSounds.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(),
            alignment: .top
        )
        .onAppear {
            drumController.setup()
        }
    }
    
    /// Setup the complete drum kit in 3D space
    private func setupDrumKit(content: RealityViewContent) async {
        let kitAnchor = AnchorEntity(world: [0, 1.0, -2])
        
        for piece in drumController.drumKit.pieces {
            do {
                // Load the 3D model for this drum piece
                let entity = try await Entity(named: piece.modelName, in: .main)
                
                // Set position relative to kit center
                entity.position = piece.position
                
                // Add collision and input components
                entity.generateCollisionShapes(recursive: true)
                entity.components.set(InputTargetComponent())
                
                // Name the entity so we can identify it on tap
                entity.name = piece.id
                
                // Debug: Log entity hierarchy
                print("📦 Loaded entity '\(entity.name)' with \(entity.children.count) children:")
                for child in entity.children {
                    print("   └─ Child: '\(child.name)'")
                }
                
                // Add to the kit
                kitAnchor.addChild(entity)
                
                print("✅ Loaded drum: \(piece.name) at position \(piece.position)")
            } catch {
                print("❌ Failed to load model for \(piece.name): \(error)")
            }
        }
        
        content.add(kitAnchor)
        print("🥁 Drum kit setup complete!")
    }
    
    /// Handle tap on a drum entity
    private func handleDrumTap(entity: Entity) {
        // Search up the entity hierarchy to find a drum ID
        // This handles cases where we tap a child entity (like "Cube" inside "kick")
        var currentEntity: Entity? = entity
        var drumId: String? = nil
        
        while currentEntity != nil && drumId == nil {
            drumId = drumController.getDrumIdFromEntity(name: currentEntity!.name)
            currentEntity = currentEntity?.parent
        }
        
        if let drumId = drumId {
            // Calculate velocity based on tap (could be enhanced with hand tracking velocity)
            let velocity: Float = Float.random(in: 0.7...1.0)
            
            // Play the drum
            drumController.hitDrum(id: drumId, velocity: velocity)
            
            // Update message
            if let piece = drumController.getDrumPiece(id: drumId) {
                message = "🥁 \(piece.name) played!"
            }
            
            print("🎵 Drum tapped: \(drumId) with velocity: \(velocity)")
        } else {
            message = "Tapped: \(entity.name)"
            print("⚠️ Tapped unknown entity: \(entity.name) (parent: \(entity.parent?.name ?? "none"))")
        }
    }
}

#Preview {
    DrumVolumeView()
}
