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

class DrumController: ObservableObject {

    static let shared = DrumController()
    private init() {}

    // MARK: Public API

    func onDrumLoaded(_ drum: DrumID) {
        if drum == .target_hi_hat_top {
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_open)
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_closed)
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_chick)
        } else {
            AudioEngine.shared.loadDrumSound(drum: drum)
        }
    }

    func onHit(drum: DrumID, velocity: Float? = nil) {
        let volume = calculateVolume(for: velocity)
        
        play(drum, volume: volume)
        sendMIDI(drum, volume: volume)
        
        if drum == .target_hi_hat_chick {
            AudioEngine.shared.stop(.target_hi_hat_open)
        }
    }
    
    // MARK: - Playback

    private func play(_ drum: DrumID, volume: Float) {
        AudioEngine.shared.playSound(drum: drum, volume: volume)
        print("🥁 Hit drum:", drum.rawValue)
    }

    private func sendMIDI(_ drum: DrumID, volume: Float) {
        let normalizedVelocity = (volume / Config.maxVolume).clamped(to: 0.0...1.0)
        MIDIBridgeClient.shared.sendDrumHit(drum: drum, velocity: normalizedVelocity)
    }

    // MARK: Velocity → Volume
    
    private func calculateVolume(for velocity: Float? = nil) -> Float {
        guard let velocity = velocity else { return Config.defaultVolume }

        let normalizedVelocity = normalizeVelocity(velocity)

        // Map the ratio to the volume range
        let volume = Config.minVolume + normalizedVelocity * (Config.maxVolume - Config.minVolume)
        return volume
    }
    
    private func normalizeVelocity(_ velocity: Float) -> Float {
        // Clamp velocity into its valid range
        let clamped = velocity.clamped(to: Config.minVelocity...Config.maxVelocity)
        // Convert velocity to a percentage between 0 and 1
        let normalized = (clamped - Config.minVelocity) / (Config.maxVelocity - Config.minVelocity)
        return normalized
    }
}
