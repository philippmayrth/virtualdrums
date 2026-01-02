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
    case target_hi_hat_pedal // pedal is pressed down
    case target_ride
    case target_crash
}

/// Main controller for the drum system
class DrumController: ObservableObject {
    
    private var isHiHatClosed: Bool = false
    
    init(appState: AppState) {
        appState.drumController = self
    }
    
    func loadDrum(drum: DrumID) {
        if (drum == .target_hi_hat) {
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_open)
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_closed)
            AudioEngine.shared.loadDrumSound(drum: .target_hi_hat_pedal)
            return
        }
        
        AudioEngine.shared.loadDrumSound(drum: drum)
    }
    
    /// Handle a drum hit with velocity detection
    func hitDrum(drum: DrumID) {
        let soundToPlay: DrumID =
                drum == .target_hi_hat
                ? (isHiHatClosed ? .target_hi_hat_closed : .target_hi_hat_open)
                : drum
        
        print("🥁 Hit drum: \(soundToPlay.rawValue)")
        AudioEngine.shared.playSound(drum: soundToPlay)
    }
    
    func toggleHiHat() {
        isHiHatClosed = !isHiHatClosed
        if isHiHatClosed {
            AudioEngine.shared.playSound(drum: .target_hi_hat_pedal)
            AudioEngine.shared.stopDrum(drum: .target_hi_hat_open)
        }
    }
}
