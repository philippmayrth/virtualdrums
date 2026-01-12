//
//  DrumController.swift
//  virtualdrums
//
//  Created by Passion on 20.11.25.
//

import AVFAudio
import Combine
import Foundation

/// Realtime audio playback engine for drum samples.
/// Owns all AVAudioPlayers and handles polyphony, kit switching, and playback.
final class AudioEngine: ObservableObject {

    static let shared = AudioEngine()
    private init(maxPolyphony: Int = 8) {
        self.maxPolyphony = maxPolyphony
    }    
    
    @Published var isReady: Bool = false /// Whether the engine has all samples loaded and is ready to play.    
    @Published var localAudioMuted: Bool = false /// If true, no local audio is produced (used for DAW monitoring / recording).

    private let maxPolyphony: Int

    private var activeKit: DrumKitID?
    private var players: [DrumID: [AVAudioPlayer]] = [:] /// One polyphonic pool per drum.
    private var playerIndex: [DrumID: Int] = [:] /// Round-robin index per drum.
        
    func setDrumKit(kit: DrumKitID) {
        guard kit != activeKit else { return }
        activeKit = kit
        reloadAllSounds()
    }
    
    // MARK: - Playback

    func playSound(drum: DrumID, volume: Float = 1.0) {
        guard !localAudioMuted else { return }        
        guard let pool = players[drum], !pool.isEmpty else {
            print("⚠️ No sound loaded for:", drum)
            return
        }
        
        // Get next available player (round-robin)
        let index = playerIndex[drum] ?? 0
        let player = pool[index]
        
        // Update index for next hit
        playerIndex[drum] = (index + 1) % pool.count
                
        player.volume = volume
        // player.rate = pitch
        player.currentTime = 0
        player.play()
        
        print("🎶 Playing sound \(drum) – at volume: \(volume)")
    }

    func stop(_ drum: DrumID) {
        players[drum]?.forEach { $0.stop() }
    }
    
    func stopAll() {
        players.values.flatMap { $0 }.forEach { $0.stop() }
    }
    
    // MARK: - Loading

    /// Loads a single sound with polyphony support for the current kit
    func loadDrumSound(drum: DrumID) {
        guard let activeKit = activeKit else {
            print("⚠️ No drum kit selected")
            return
        }

        guard players[drum] == nil else { 
            print("Player for \(drum.rawValue) already loaded. Skipping.")
            return
        }
        
        let fileName = "\(activeKit)_\(drum)"

        guard let url = findAudioFile(named: fileName) else {
            print("⚠️ Missing sound:", fileName)
            return
        }
        
        players[drum] = makePolyphonicPlayers(from: url)
        playerIndex[drum] = 0
    }
    
    private func reloadAllSounds() {
        print("🔄 Loading sounds of drum kit: \(activeKit!.rawValue)")
        
        isReady = false
        stopAll()

        // Store existing drum names
        let drums = players.keys

        // Reset state
        players.removeAll()
        playerIndex.removeAll()

        // Reload all drums
        for drum in drums {
            loadDrumSound(drum: drum)
        }

        isReady = true
    }
    
    // MARK: - Helpers

    private func findAudioFile(named name: String) -> URL? {
        ["aif", "aiff", "wav", "m4a", "mp3"]
            .compactMap { Bundle.main.url(forResource: name, withExtension: $0) }
            .first
    }

    private func makePolyphonicPlayers(from url: URL) -> [AVAudioPlayer] {
        var pool: [AVAudioPlayer] = []

        for _ in 0..<maxPolyphony {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.enableRate = true // Allow pitch shifting
                pool.append(player)
            } catch {
                print("❌ Failed to load:", url.lastPathComponent, error)
                return []
            }
        }

        return pool
    }
}
