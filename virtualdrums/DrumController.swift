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
    
    /// Handle a drum hit with velocity detection
    func hitDrum(drum: DrumID) {
        AudioEngine.shared.playSound(drum: drum)
    }
    
}

