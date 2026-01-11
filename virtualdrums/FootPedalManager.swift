//
//  FootPedalManager.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 02.01.26.
//

import GameController
import Foundation
import Combine

final class FootPedalManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = FootPedalManager()
    private init() {}
    
    // MARK: - Controller State
    
    @Published private(set) var isControllerConnected: Bool = false
    private var connectedControllers: [GCController] = []
    
    public var controllerNames: [String] {
        connectedControllers.map { $0.vendorName ?? "Unknown controller" }
    }
    
    // MARK: - Pedal State

    struct PedalState {
        var isTouching: Bool = false
        var distance: Float = 1.0
        var velocity: Float = 0.0
        var lastDistance: Float = 1.0
        var lastTime: TimeInterval = 0
    }

    @Published private(set) var hiHat = PedalState()
    @Published private(set) var kick  = PedalState()
    
    // MARK: - Public API
    
    func startListening() {
        GCController.controllers().forEach { attach($0) }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let controller = note.object as? GCController else { return }
            self?.attach(controller)
        }
        
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let controller = note.object as? GCController else { return }
            self?.detach(controller)
        }
        
        GCController.startWirelessControllerDiscovery {}
    }

    /// Method for toggling the hi-hat without a press/release state.
    /// Used for the alternative interaction of tapping the hi-hat model.
    @MainActor func toggleHiHat() {
        if self.hiHat.isTouching {
            self.hiHat.distance = 1.0
            self.hiHat.isTouching = false
        } else {
            self.hiHat.distance = 0.0
            self.hiHat.velocity = 5.0
            self.hiHat.isTouching = true
        }
    }
    
    // MARK: - Controller Mapping
    
    /// Maps a standard game controller to two virtual drum pedals.
    /// The controller is split into left and right halves: the left side inputs control the Hi-Hat pedal and the right side inputs control the kick pedal.

    private func attach(_ controller: GCController) {
        guard let gamepad = controller.extendedGamepad else { return }
        guard !connectedControllers.contains(where: { $0 === controller }) else { return } // prevent duplicates
        
        connectedControllers.append(controller)
        isControllerConnected = true
        
        // LEFT SIDE BUTTONS → HI-HAT

        gamepad.leftTrigger.valueChangedHandler = { _, value, _ in
            self.update(&self.hiHat, value: value)
        }

        gamepad.leftShoulder.pressedChangedHandler = { _, _, pressed in
            self.update(&self.hiHat, value: pressed ? 1 : 0)
        }

        gamepad.dpad.valueChangedHandler = { _, x, y in
            self.update(&self.hiHat, value: max(abs(x), abs(y)))
        }

        gamepad.leftThumbstick.valueChangedHandler = { _, x, y in
            self.update(&self.hiHat, value: max(abs(x), abs(y)))
        }

        // RIGHT SIDE BUTTONS → KICK

        gamepad.rightTrigger.valueChangedHandler = { _, value, _ in
            self.update(&self.kick, value: value)
        }

        gamepad.rightShoulder.pressedChangedHandler = { _, _, pressed in
            self.update(&self.kick, value: pressed ? 1 : 0)
        }

        gamepad.buttonA.pressedChangedHandler = { _, _, pressed in
            self.update(&self.kick, value: pressed ? 1 : 0)
        }

        gamepad.buttonB.pressedChangedHandler = { _, _, pressed in
            self.update(&self.kick, value: pressed ? 1 : 0)
        }

        gamepad.buttonX.pressedChangedHandler = { _, _, pressed in
            self.update(&self.kick, value: pressed ? 1 : 0)
        }

        gamepad.buttonY.pressedChangedHandler = { _, _, pressed in
            self.update(&self.kick, value: pressed ? 1 : 0)
        }

        gamepad.rightThumbstick.valueChangedHandler = { _, x, y in
            self.update(&self.kick, value: max(abs(x), abs(y)))
        }

        // Intentionally ignoring: buttonMenu, buttonOptions, buttonHome

        print("🥁 Controller connected: \(controller.vendorName ?? "Unknown")")
    }
    
    private func detach(_ controller: GCController) {
        connectedControllers.removeAll { $0 === controller }
        isControllerConnected = !connectedControllers.isEmpty
        print("🔌 Controller disconnected: \(controller.vendorName ?? "Unknown")")
    }
    
    // MARK: - Pedal math
    
    @MainActor
    private func update(_ pedal: inout PedalState, value: Float) {
        let now = CACurrentMediaTime()
        let distance = 1 - value

        let deltaDistance = pedal.lastDistance - distance
        let deltaTime = max(now - pedal.lastTime, 0.001)
                                                
        pedal.velocity = deltaDistance / Float(deltaTime)
        pedal.distance = distance
        pedal.isTouching = distance == 0
        
        pedal.lastDistance = distance
        pedal.lastTime = now
    }
}
