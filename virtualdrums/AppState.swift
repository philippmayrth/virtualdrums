//
//  AppState.swift
//  virtualdrums
//
//  Created by Passion on 21.11.25.
//

import Foundation
import SwiftUI
import Combine

/// Shared app state for passing data between scenes
@MainActor
class AppState: ObservableObject {
    @Published var selectedDrumKit: DrumKitID = .bite {
        didSet {
            AudioEngine.shared.setDrumKit(kit: selectedDrumKit)
        }
    }
    @Published var isImmersiveSpaceOpen: Bool = false
}
