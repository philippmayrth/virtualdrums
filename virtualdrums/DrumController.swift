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

enum DrumID: String, CaseIterable {
    case target_snare
    case target_bass_drum // aka. kick
    case target_floor_tom
    case target_mid_tom
    case target_high_tom
    case target_hi_hat_top // hi-hat entity
    case target_hi_hat_open // hi-hat sound (stick)
    case target_hi_hat_closed // hi-hat sound (stick)
    case target_hi_hat_chick // hi-hat sound (pedal)
    case target_ride
    case target_crash
}

class DrumController: ObservableObject {
    
    // MARK: Singleton
    static let shared = DrumController()
    private init() {}
        

    // MARK: Public API

    func loadDrum(drum: DrumID) {
        if drum == .target_hi_hat_top {
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_open)
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_closed)
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_chick)
        } else {
            AudioEngine.shared.loadDrumSound(drum: drum)
        }
    }
    
    /// Generic drum hit (used by hands, sticks, etc.)
    func hitDrum(drum: DrumID, strikeSpeed: Float?, isHiHatClosed: Bool) {
        if (drum == .target_hi_hat_chick) {
            AudioEngine.shared.stopDrum(drum: .target_hi_hat_open)
        }
        
        let soundToPlay: DrumID =
                drum == .target_hi_hat_top
                ? (isHiHatClosed ? .target_hi_hat_closed : .target_hi_hat_open)
                : drum
        
        let volume: Float
        if (strikeSpeed != nil) {
            volume = calculateVolume(forSpeed: strikeSpeed!)
            AudioEngine.shared.playSound(drum: soundToPlay, volume: volume)
        } else {
            volume = 1.0
            AudioEngine.shared.playSound(drum: soundToPlay)
        }
   
        print("🥁 Hit drum: \(soundToPlay.rawValue)")
        
        // Send to MIDI bridge
        let normalizedVelocity = min(max(volume / 3.0, 0.0), 1.0) // Normalize volume to 0-1
        MIDIBridgeClient.shared.sendDrumHit(drum: soundToPlay, velocity: normalizedVelocity)
    }

    // MARK: Velocity → Volume Mapping
    
    private func calculateVolume(forSpeed speed: Float) -> Float {
        let minSpeed: Float = 0.1
        let maxSpeed: Float = 15.0

        let clampedSpeed = min(max(speed, minSpeed), maxSpeed)
        let normalized = (clampedSpeed - minSpeed) / (maxSpeed - minSpeed)

        let minVolume: Float = 0.1
        let maxVolume: Float = 3

        let volume = minVolume + normalized * (maxVolume - minVolume)
        return volume
    }
}
