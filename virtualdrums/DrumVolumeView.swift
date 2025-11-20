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
        let kitAnchor = AnchorEntity(world: [0, 0, -1.5])  // Y=0 puts it on the ground
        
        do {
            // Load the functional drum kit with named parts (ugly but works!)
            let drumKitEntity = try await Entity(named: "DrumKit_Named", in: .main)
            
            // Scale and position the entire kit
            drumKitEntity.scale = [0.01, 0.01, 0.01]
            drumKitEntity.position = [0, 0, 0]  // Reset to center of anchor
            
            print("📦 Loaded DrumKit_Named model")
            
            // Find and configure drum parts with proper names
            configureDrumParts(entity: drumKitEntity)
            
            // Add collision to entire kit
            drumKitEntity.generateCollisionShapes(recursive: true)
            
            // Add to anchor
            kitAnchor.addChild(drumKitEntity)
            content.add(kitAnchor)
            
            print("🥁 Drum kit setup complete!")
            
        } catch {
            print("❌ Failed to load DrumKit_Named model: \(error)")
        }
    }
    
    /// Configure drum parts by finding entities with drum names and adding input targets
    private func configureDrumParts(entity: Entity) {
        // Map of entity name patterns to drum IDs for DrumKit_Named
        let drumMapping: [String: String] = [
            "Snare_Skin": "snare",
            "Bass_Outer_Skin": "kick",
            "TomTom_Skin": "tom1",
            "Cymbol": "crash",  // Cymbal is misspelled in the model
        ]
        
        // Recursively search for drum parts
        searchAndConfigureEntities(entity, drumMapping: drumMapping, depth: 0)
    }
    
    /// Recursively search entities and configure drum parts
    private func searchAndConfigureEntities(_ entity: Entity, drumMapping: [String: String], depth: Int) {
        let entityName = entity.name
        
        // Debug: Log ALL entities at reasonable depth
        if depth < 8 {
            let indent = String(repeating: "  ", count: depth)
            print("\(indent)🔍 Entity[\(depth)]: '\(entityName)'")
        }
        
        // Check if this entity matches any drum pattern
        for (pattern, drumId) in drumMapping {
            if entityName.contains(pattern) {
                // Found a drum part! Make it tappable
                entity.components.set(InputTargetComponent())
                
                // Store the drum ID in the entity name or use a custom property
                // For now, we'll append it to help with detection
                if !entity.name.contains("_DRUM_") {
                    entity.name = "\(entity.name)_DRUM_\(drumId)"
                    print("✅ Configured: \(pattern) → \(drumId) (\(entityName))")
                }
                break
            }
        }
        
        // Continue searching children
        for child in entity.children {
            searchAndConfigureEntities(child, drumMapping: drumMapping, depth: depth + 1)
        }
    }
    
    /// Handle tap on a drum entity
    private func handleDrumTap(entity: Entity) {
        // Log detailed tap information
        print("👆 TAP DETECTED:")
        print("   Entity: \(entity.name)")
        print("   Position: \(entity.position(relativeTo: nil))")
        print("   Parent: \(entity.parent?.name ?? "none")")
        
        // Search up the entity hierarchy to find a drum ID
        // This handles cases where we tap a child entity (like "Cube" inside "kick")
        var currentEntity: Entity? = entity
        var drumId: String? = nil
        var searchDepth = 0
        
        while currentEntity != nil && drumId == nil {
            let entityName = currentEntity!.name
            print("   Checking entity[\(searchDepth)]: \(entityName)")
            drumId = drumController.getDrumIdFromEntity(name: entityName)
            if drumId != nil {
                print("   ✅ Found drum ID: \(drumId!) at depth \(searchDepth)")
            }
            currentEntity = currentEntity?.parent
            searchDepth += 1
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
            print("❌ NO DRUM ID FOUND - hierarchy searched up \(searchDepth) levels")
            print("   Entity name: \(entity.name)")
            print("   Available drums: \(drumController.drumKit.pieces.map { $0.id }.joined(separator: ", "))")
        }
    }
}

#Preview {
    DrumVolumeView()
}
