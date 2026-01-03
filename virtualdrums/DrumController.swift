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
    case target_bass_drum
    case target_floor_tom
    case target_mid_tom
    case target_high_tom
    case target_hi_hat // generic input
    case target_hi_hat_open
    case target_hi_hat_closed
    case target_hi_hat_pedal // pedal is pressed down // TODO: rename to target_hi_hat_chick
    case target_ride
    case target_crash
}

/// Main controller for the drum system
class DrumController: ObservableObject {
    
    // MARK: Singleton

    static let shared = DrumController()

    private init() {
        bindFootPedals()
    }

    // MARK: Setup

    private let pedal = FootPedalManager.shared
    private var cancellables = Set<AnyCancellable>()    

    private func bindFootPedals() {

        // Kick drum pedal
        pedal.$isKickHit
            .removeDuplicates()
            .filter { $0 } // only on hit
            .sink { [weak self] _ in
                guard let self else { return }
                self.hitDrum(
                    drum: .target_bass_drum,
                    strikeSpeed: pedal.kickVelocity
                )
            }
            .store(in: &cancellables)

        // Hi-hat pedal ("chick")
        pedal.$isHiHatClosed
            .removeDuplicates()
            .sink { [weak self] closed in
                guard let self else { return }
                if closed {
                    self.onHiHatClosed(velocity: pedal.hiHatVelocity)
                } else {
                    // onHiHatOpened
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Public API

    func loadDrum(drum: DrumID) {
        if drum == .target_hi_hat {
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_open)
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_closed)
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_pedal)
        } else {
            AudioEngine.shared.loadDrumSound(drum: drum)
        }
    }
    
    /// Generic drum hit (used by hands, sticks, etc.)
    func hitDrum(drum: DrumID, strikeSpeed: Float?) {
        let soundToPlay: DrumID =
                drum == .target_hi_hat
                ? (FootPedalManager.shared.isHiHatClosed ? .target_hi_hat_closed : .target_hi_hat_open)
                : drum
        
        if (strikeSpeed != nil) {
            let volume: Float = calculateVolume(forSpeed: strikeSpeed!)
            AudioEngine.shared.playSound(drum: soundToPlay, volume: volume)
        } else {
            AudioEngine.shared.playSound(drum: soundToPlay)
        }
   
        print("🥁 Hit drum: \(soundToPlay.rawValue)")
    }
    
    // MARK: Hi-hat Pedal

     private func onHiHatClosed(velocity: Float) {
        hitDrum(drum: .target_hi_hat_pedal, strikeSpeed: velocity)
        AudioEngine.shared.stopDrum(drum: .target_hi_hat_open)
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
