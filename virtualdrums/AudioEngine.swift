//
//  DrumController.swift
//  virtualdrums
//
//  Created by Passion on 20.11.25.
//

import AVFAudio
import Combine

final class AudioEngine: ObservableObject {

    // MARK: - Singleton
    static let shared = AudioEngine()
    private init(maxPolyphony: Int = 8) {
        self.maxPolyphony = maxPolyphony
    }

    // MARK: - Audio Engine
    
    @Published var isReady: Bool = false
    private var audioPlayers: [String: [AVAudioPlayer]] = [:]
    private var currentPlayerIndex: [String: Int] = [:]
    private let maxPolyphony: Int
    private var selectedDrumKit: DrumKitID?
    let volumeJitter: Float = 0.04   // ±4%
    let pitchJitter: Float = 0.015   // ±1.5%
    
    func setDrumKit(kit: DrumKitID) {
        self.selectedDrumKit = kit
        self.loadDrumKit(kit: kit)
    }
    
    func playSound(drumName: String) {
        guard let players = audioPlayers[drumName], !players.isEmpty else {
            print("⚠️ No audio player available for drum: \(drumName)")
            return
        }
        
        // Get next available player (round-robin)
        let index = currentPlayerIndex[drumName] ?? 0
        let player = players[index]
        
        // Update index for next hit
        currentPlayerIndex[drumName] = (index + 1) % players.count
        
        // Add random variation to voluem and pitch (TODO: use real velocity and hit position)
        let volume = 1 + randomOffset(volumeJitter)
        player.volume = volume
        let pitch = 1 +  randomOffset(pitchJitter)
        player.rate = pitch
        
        // Reset to beginning and play
        player.currentTime = 0
        player.play()
        print("🥁 Playing \(drumName) - volume: \(volume), pitch: \(pitch)")
    }
    
    /// Load a single sound with polyphony support
    func loadDrumSound(drumName: String) {
        guard let selectedDrumKit else {
            print("⚠️ No drum kit selected")
            return
        }

        let fileName = "\(selectedDrumKit)_\(drumName)"

        // Try multiple file extensions
        let extensions = ["aif", "wav", "m4a", "mp3", "aiff"]
        guard let url = extensions.compactMap({ ext in
            Bundle.main.url(forResource: fileName, withExtension: ext)
        }).first else {
            print("⚠️ Sound file not found: \(fileName)")
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
                print("❌ Error loading sound \(drumName): \(error)")
                return
            }
        }
        
        audioPlayers[drumName] = players
        currentPlayerIndex[drumName] = 0
        print("✅ Loaded \(drumName) with \(maxPolyphony)x polyphony")
    }
    
    private func loadDrumKit(kit: DrumKitID) {
        print("🔄 Loading drum kit sounds: \(kit)")

        // 1. Mark engine as busy
        isReady = false

        // 2. Stop all currently playing sounds
        stopAll()

        // 3. Store existing drum names
        let drumNames = Array(audioPlayers.keys)

        // 4. Reset state
        audioPlayers.removeAll()
        currentPlayerIndex.removeAll()

        // 6. Reload all drums with the new kit prefix
        for drumName in drumNames {
            loadDrumSound(drumName: drumName)
        }

        // 7. Ready to play
        isReady = true

        print("✅ Drum kit sounds loaded: \(kit)")
    }
        
    /// Stop all sounds
    func stopAll() {
        for players in audioPlayers.values {
            players.forEach { $0.stop() }
        }
    }
    
    func randomOffset(_ amount: Float) -> Float {
        Float.random(in: -amount...amount)
    }
}
