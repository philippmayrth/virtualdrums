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
    case target_hi_hat
    case target_ride
    case target_crash
}

/// Main controller for the drum system
class DrumController: ObservableObject {
    
    init(appState: AppState) {
        appState.drumController = self
    }
    
    /// Handle a drum hit with velocity detection
    func hitDrum(drum: DrumID) {
        print("🥁 Hit drum: \(drum.rawValue)")
        AudioEngine.shared.playSound(drum: drum)
    }

    
    func hitHiHat(isOpen: Bool) {
        if isOpen {
            AudioEngine.shared.playSound(drum: .target_hi_hat)
        } else {
            // Placeholder so open/closed is audible even without separate samples.
            AudioEngine.shared.playSound(drum: .target_bass_drum)
        }
    }
    
    func toggleHiHat() {
        print("toggle")
    }

    func closeHiHat() {
        AudioEngine.shared.stopDrum(drum: .target_hi_hat)
    }
    
}
