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
    @Published var selectedDrumKit: DrumKitID = .bite
    @Published var selectedDrumSet: DrumSetID = .burgundy_drum
    @Published var isImmersiveSpaceOpen: Bool = false
    @Published var keyboardInputMode: KeyboardInputMode = {
        #if targetEnvironment(simulator)
        return .textField
        #else
        return .hardware
        #endif
    }()
    @Published var keyboardKickTriggerToken: Int = 0
    @Published var keyboardHiHatTriggerToken: Int = 0
    @Published var hiHatPedalIsClosed: Bool = true
#if targetEnvironment(simulator)
    @Published var simulator = SimulatorState()
#endif // targetEnvironment(simulator)
    
    /// Stores Combine subscriptions to keep them alive
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe changes to `selectedDrumKit`
        $selectedDrumKit
            // This sink is called:
            // - immediately with the initial value
            // - every time `selectedDrumKit` changes
            .sink { kit in
                AudioEngine.shared.setDrumKit(kit: kit)
            }
            // Store the subscription so it stays active for the lifetime of AppState
            .store(in: &cancellables)

#if targetEnvironment(simulator)
        simulator.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
#endif // targetEnvironment(simulator)
    }
}
