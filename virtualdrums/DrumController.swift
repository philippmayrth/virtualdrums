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
        let normalizedVelocity = min(max(volume / 3.0, 0.0), 1.0)
        MIDIBridgeClient.shared.sendDrumHit(drum: drum, velocity: normalizedVelocity)
    }

    // MARK: Velocity → Volume
    
    private func calculateVolume(for velocity: Float? = nil) -> Float {
        guard let velocity = velocity else { return Config.defaultVolume }

        let minVelocity: Float = 0.1
        let maxVelocity: Float = 15.0

        let clampedVelocity = min(max(velocity, minVelocity), maxVelocity)
        let normalized = (clampedVelocity - minVelocity) / (maxVelocity - minVelocity)

        let minVolume: Float = 0.1
        let maxVolume: Float = 3

        let volume = minVolume + normalized * (maxVolume - minVolume)
        return volume
    }
}
