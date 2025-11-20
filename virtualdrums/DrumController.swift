//
//  DrumController.swift
//  virtualdrums
//
//  Created by Passion on 20.11.25.
//

import Foundation
import Combine
import AVFoundation
import RealityKit

// MARK: - Drum Kit Configuration

/// Represents a single drum piece in the kit
struct DrumPiece: Identifiable {
    let id: String
    let name: String
    let soundFileName: String // Logic Pro exported sound file name (without extension)
    let position: SIMD3<Float> // Position relative to kit center
    let modelName: String // 3D model for this drum
    
    // Drum-specific properties
    var velocity: Float = 1.0 // Hit velocity multiplier
    var pitch: Float = 1.0 // Pitch adjustment
}

/// Standard drum kit configuration
struct DrumKit {
    var pieces: [DrumPiece]
    let name: String
    let description: String
    
    // Bite Kit - Aggressive drum sounds
    static let bite = DrumKit(
        pieces: [
            DrumPiece(id: "kick", name: "Kick Drum", soundFileName: "Bite_kick",
                      position: [0, 0, 0.5], modelName: "TestCube"),
            DrumPiece(id: "snare", name: "Snare Drum", soundFileName: "Bite_snare",
                      position: [-0.3, 0.1, 0], modelName: "TestCube"),
            DrumPiece(id: "hihat", name: "Hi-Hat", soundFileName: "Bite_hihat",
                      position: [0.3, 0.15, 0], modelName: "TestCube"),
            DrumPiece(id: "tom1", name: "Tom 1", soundFileName: "Bite_tom1",
                      position: [-0.2, 0.2, -0.2], modelName: "TestCube"),
            DrumPiece(id: "tom2", name: "Tom 2", soundFileName: "Bite_tom2",
                      position: [0, 0.2, -0.2], modelName: "TestCube"),
            DrumPiece(id: "tom3", name: "Tom 3", soundFileName: "Bite_tom3",
                      position: [0.4, 0, 0.2], modelName: "TestCube"),
            DrumPiece(id: "crash", name: "Crash Cymbal", soundFileName: "Bite_crash",
                      position: [-0.5, 0.4, -0.3], modelName: "TestCube"),
            DrumPiece(id: "ride", name: "Ride Cymbal", soundFileName: "Bite_ride",
                      position: [0.5, 0.35, -0.3], modelName: "TestCube")
        ],
        name: "Bite Kit",
        description: "Aggressive, punchy drum sounds"
    )
    
    // Kick Kit - Deep, powerful drum sounds
    static let kick = DrumKit(
        pieces: [
            DrumPiece(id: "kick", name: "Kick Drum", soundFileName: "Kick_kick",
                      position: [0, 0, 0.5], modelName: "TestCube"),
            DrumPiece(id: "snare", name: "Snare Drum", soundFileName: "Kick_snare",
                      position: [-0.3, 0.1, 0], modelName: "TestCube"),
            DrumPiece(id: "hihat", name: "Hi-Hat", soundFileName: "Kick_hihat",
                      position: [0.3, 0.15, 0], modelName: "TestCube"),
            DrumPiece(id: "tom1", name: "Tom 1", soundFileName: "Kick_tom1",
                      position: [-0.2, 0.2, -0.2], modelName: "TestCube"),
            DrumPiece(id: "tom2", name: "Tom 2", soundFileName: "Kick_tom2",
                      position: [0, 0.2, -0.2], modelName: "TestCube"),
            DrumPiece(id: "tom3", name: "Tom 3", soundFileName: "Kick_tom3",
                      position: [0.4, 0, 0.2], modelName: "TestCube"),
            DrumPiece(id: "crash", name: "Crash Cymbal", soundFileName: "Kick_crash",
                      position: [-0.5, 0.4, -0.3], modelName: "TestCube"),
            DrumPiece(id: "ride", name: "Ride Cymbal", soundFileName: "Kick_ride",
                      position: [0.5, 0.35, -0.3], modelName: "TestCube")
        ],
        name: "Kick Kit",
        description: "Deep, powerful drum sounds"
    )
    
    // Squeeze Kit - Tight, compressed drum sounds
    static let squeeze = DrumKit(
        pieces: [
            DrumPiece(id: "kick", name: "Kick Drum", soundFileName: "Squeeze_kick",
                      position: [0, 0, 0.5], modelName: "TestCube"),
            DrumPiece(id: "snare", name: "Snare Drum", soundFileName: "Squeeze_snare",
                      position: [-0.3, 0.1, 0], modelName: "TestCube"),
            DrumPiece(id: "hihat", name: "Hi-Hat", soundFileName: "Squeeze_hihat",
                      position: [0.3, 0.15, 0], modelName: "TestCube"),
            DrumPiece(id: "tom1", name: "Tom 1", soundFileName: "Squeeze_tom1",
                      position: [-0.2, 0.2, -0.2], modelName: "TestCube"),
            DrumPiece(id: "tom2", name: "Tom 2", soundFileName: "Squeeze_tom2",
                      position: [0, 0.2, -0.2], modelName: "TestCube"),
            DrumPiece(id: "tom3", name: "Tom 3", soundFileName: "Squeeze_tom3",
                      position: [0.4, 0, 0.2], modelName: "TestCube"),
            DrumPiece(id: "crash", name: "Crash Cymbal", soundFileName: "Squeeze_crash",
                      position: [-0.5, 0.4, -0.3], modelName: "TestCube"),
            DrumPiece(id: "ride", name: "Ride Cymbal", soundFileName: "Squeeze_ride",
                      position: [0.5, 0.35, -0.3], modelName: "TestCube")
        ],
        name: "Squeeze Kit",
        description: "Tight, compressed drum sounds"
    )
    
    // Registry of all available kits
    static let allKits: [String: DrumKit] = [
        "bite": bite,
        "kick": kick,
        "squeeze": squeeze
    ]
    
    // Get kit by name, with fallback
    static func kit(named name: String) -> DrumKit {
        return allKits[name] ?? bite
    }
}

// MARK: - Polyphonic Audio Engine

/// Audio engine that supports playing multiple drum sounds simultaneously
class PolyphonicDrumAudioEngine: ObservableObject {
    private var audioPlayers: [String: [AVAudioPlayer]] = [:]
    private var currentPlayerIndex: [String: Int] = [:]
    private let maxPolyphony: Int
    
    @Published var isReady: Bool = false
    @Published var loadedSounds: Set<String> = []
    @Published var failedSounds: Set<String> = []
    
    init(maxPolyphony: Int = 8) {
        self.maxPolyphony = maxPolyphony
    }
    
    /// Load all drum sounds for a drum kit
    func loadDrumKit(_ drumKit: DrumKit) {
        for piece in drumKit.pieces {
            loadSound(named: piece.soundFileName, forDrum: piece.id)
        }
        isReady = true
    }
    
    /// Load a single sound with polyphony support
    private func loadSound(named soundName: String, forDrum drumId: String) {
        // Try multiple file extensions and Logic Pro naming patterns
        let extensions = ["mp3", "wav", "m4a", "aif", "aiff"]
        let namingPatterns = [soundName, "\(soundName)_1", "\(soundName) 1", "\(soundName)-1"]
        
        // Search through all naming pattern + extension combinations
        guard let url = namingPatterns.flatMap({ pattern in
            extensions.compactMap({ ext in
                Bundle.main.url(forResource: pattern, withExtension: ext)
            })
        }).first else {
            print("⚠️ Sound file not found: \(soundName) (tried patterns: \(namingPatterns.joined(separator: ", ")))")
            failedSounds.insert(drumId)
            return
        }
        
        var players: [AVAudioPlayer] = []
        
        // Create multiple player instances for polyphony
        for _ in 0..<maxPolyphony {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.enableRate = true // Allow pitch shifting
                players.append(player)
            } catch {
                print("❌ Error loading sound \(soundName): \(error)")
                failedSounds.insert(drumId)
                return
            }
        }
        
        audioPlayers[drumId] = players
        currentPlayerIndex[drumId] = 0
        loadedSounds.insert(drumId)
        
        print("✅ Loaded \(soundName) with \(maxPolyphony)x polyphony")
    }
    
    /// Play a drum sound with velocity and pitch control
    func playDrum(_ drumId: String, velocity: Float = 1.0, pitch: Float = 1.0) {
        guard let players = audioPlayers[drumId], !players.isEmpty else {
            print("⚠️ No audio player available for drum: \(drumId)")
            return
        }
        
        // Get next available player (round-robin)
        let index = currentPlayerIndex[drumId] ?? 0
        let player = players[index]
        
        // Update index for next hit
        currentPlayerIndex[drumId] = (index + 1) % players.count
        
        // Apply velocity (volume)
        player.volume = min(max(velocity, 0.0), 1.0)
        
        // Apply pitch shift (rate change)
        // Rate values: 0.5 = down octave, 1.0 = normal, 2.0 = up octave
        player.rate = min(max(pitch, 0.5), 2.0)
        
        // Reset to beginning and play
        player.currentTime = 0
        player.play()
        
        print("🥁 Playing \(drumId) - velocity: \(velocity), pitch: \(pitch)")
    }
    
    /// Stop all sounds
    func stopAll() {
        for players in audioPlayers.values {
            players.forEach { $0.stop() }
        }
    }
}

// MARK: - Drum Controller

/// Main controller for the drum system
class DrumController: ObservableObject {
    @Published var drumKit: DrumKit
    @Published var audioEngine: PolyphonicDrumAudioEngine
    @Published var lastHitDrum: String?
    @Published var hitCount: Int = 0
    
    init(drumKit: DrumKit = .bite, maxPolyphony: Int = 8) {
        self.drumKit = drumKit
        self.audioEngine = PolyphonicDrumAudioEngine(maxPolyphony: maxPolyphony)
    }
    
    /// Initialize the drum system
    func setup() {
        audioEngine.loadDrumKit(drumKit)
        print("🎵 Drum system initialized with \(drumKit.pieces.count) drums")
    }
    
    /// Handle a drum hit with velocity detection
    func hitDrum(id: String, velocity: Float = 1.0) {
        guard let piece = drumKit.pieces.first(where: { $0.id == id }) else {
            print("⚠️ Unknown drum ID: \(id)")
            return
        }
        
        // Calculate final velocity with piece-specific multiplier
        let finalVelocity = velocity * piece.velocity
        
        // Play with piece-specific pitch
        audioEngine.playDrum(id, velocity: finalVelocity, pitch: piece.pitch)
        
        // Update state
        lastHitDrum = piece.name
        hitCount += 1
    }
    
    /// Map entity name to drum ID
    func getDrumIdFromEntity(name: String) -> String? {
        // Extract drum ID from entity name
        // Supports formats like: "Drum_kick", "kick", "kick_mesh", "Cube" (inside kick parent), etc.
        let lowercased = name.lowercased()
        
        // First try exact match
        if drumKit.pieces.contains(where: { $0.id == lowercased }) {
            return lowercased
        }
        
        // Then try partial match (entity name contains drum ID)
        for piece in drumKit.pieces {
            if lowercased.contains(piece.id) {
                return piece.id
            }
        }
        
        // No match found - might be a child entity like "Cube"
        // The caller should search up the entity hierarchy
        return nil
    }
    
    /// Get drum piece configuration
    func getDrumPiece(id: String) -> DrumPiece? {
        drumKit.pieces.first(where: { $0.id == id })
    }
}
