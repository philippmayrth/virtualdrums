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

// MARK: - Drum Controller

/// Main controller for the drum system
class DrumController: ObservableObject {
    
    /// Handle a drum hit with velocity detection
    func hitDrum(drum: String) {
        AudioEngine.shared.playSound(drumName: drum)
    }
    
}

