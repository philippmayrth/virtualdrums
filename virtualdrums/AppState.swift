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
    @Published var selectedDrumKit: DrumKitID = Config.defaultSelectedDrumKit
    @Published var selectedDrumSet: DrumSetID = Config.defaultSelectedDrumSet
    @Published var isImmersiveSpaceOpen: Bool = false
    @Published var isHiHatClosed: Bool = false
    @Published var handedness: Handedness = .right
    
    @Published var stickHandleLength: Float = Config.initialStickHandleLength
    @Published var drumScale: Float = 1
    @Published var drumDistance: Float = 0
    @Published var drumHeight: Float = 0

    #if targetEnvironment(simulator)
    @Published var simulator = SimulatorState()
    #endif // targetEnvironment(simulator)
    
    /// Stores Combine subscriptions to keep them alive
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        bindAudioEngine()
        bindMIDIBridge()
        bindSimulator()
    }

    /// Routes UI kit selection into the audio engine.
    private func bindAudioEngine() {
        $selectedDrumKit
            .removeDuplicates()
            .sink { kit in
                AudioEngine.shared.setDrumKit(kit: kit)
            }
            .store(in: &cancellables)
    }

    /// Routes UI kit selections to external MIDI hardware.
    private func bindMIDIBridge() {
        $selectedDrumKit
            .removeDuplicates()
            .sink { kit in
                MIDIBridgeClient.shared.sendKitSelection(drumKit: kit)
            }
            .store(in: &cancellables)

        $selectedDrumSet
            .removeDuplicates()
            .sink { set in
                MIDIBridgeClient.shared.sendKitSelection(soundKit: set)
            }
            .store(in: &cancellables)
    }

    #if targetEnvironment(simulator)
        /// Ensures simulator sub-state updates propagate to SwiftUI.
        private func bindSimulator() {
            simulator.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    #else
        private func bindSimulator() {}
    #endif // targetEnvironment(simulator)
}
