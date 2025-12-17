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
    @Published var selectedDrumKitName: String = "bite" {
        didSet {
            AudioEngine.shared.setDrumKit(kitName: selectedDrumKitName)
        }
    }
    @Published var isImmersiveSpaceOpen: Bool = false
}
