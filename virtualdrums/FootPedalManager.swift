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
    
    static let shared = FootPedalManager()
    
    @Published private(set) var isControllerConnected: Bool = false
    @Published private(set) var connectedControllers: [GCController] = []
    var controllerNames: [String] {
        connectedControllers.map {
            $0.vendorName ?? "Unknown controller"
        }
    }
    
    // Hi-hat pedal state
    @Published private(set) var hiHatPedalDistance: Float = 1.0
    @Published private(set) var isHiHatClosed = false
    @Published private(set) var hiHatVelocity: Float = 0.0
    private var lastHiHatDistance: Float = 1.0
    private var lastHiHatTime: TimeInterval = 0
    
    // Kick drum pedal state
    @Published private(set) var kickPedalDistance: Float = 1.0
    @Published private(set) var isKickHit = false
    @Published private(set) var kickVelocity: Float = 0.0
    private var lastKickDistance: Float = 1.0
    private var lastKickTime: TimeInterval = 0
    
    func startListening() {
        GCController.controllers().forEach { setup($0) }
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let controller = note.object as? GCController else { return }
            self?.setup(controller)
        }
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let controller = note.object as? GCController else { return }
            self?.remove(controller)
        }
    }
    
    /// Method for toggling the hi-hat without a press/release state.
    /// Used for the alternative interaction of tapping the hi-hat model.
    @MainActor func toggleHiHat() {
        if isHiHatClosed {
            self.hiHatPedalDistance = 1.0
            self.isHiHatClosed = false
        } else {
            self.hiHatPedalDistance = 0.0
            self.hiHatVelocity = 5.0
            self.isHiHatClosed = true
        }
    }
    
    /// We divide the standard controller in a left and right side:
    /// - Left side (D-Pad, Left Trigger, Left Shoulder, Left Thumbstick) → Hi-Hat Pedal
    /// - Right side (Face Buttons, Right Trigger, Right Shoulder, Right Thumbstick) → Kick Drum Pedal
    private func setup(_ controller: GCController) {    
        guard let gamepad = controller.extendedGamepad else { return }

        // Prevent duplicates
        if connectedControllers.contains(where: { $0 === controller }) {
            return
        }
        connectedControllers.append(controller)
        isControllerConnected = true
        
        // MARK: Triggers
        gamepad.leftTrigger.valueChangedHandler = { _, value, _ in
            self.handleHiHat(value: value)
        }

        gamepad.rightTrigger.valueChangedHandler = { _, value, _ in
            self.handleKick(value: value)
        }

        // MARK: Shoulders
        gamepad.leftShoulder.pressedChangedHandler = { _, _, pressed in
            self.handleHiHat(value: pressed ? 1.0 : 0.0)
        }

        gamepad.rightShoulder.pressedChangedHandler = { _, _, pressed in
            self.handleKick(value: pressed ? 1.0 : 0.0)
        }

        // MARK: Face Buttons (RIGHT SIDE → Kick)
        gamepad.buttonA.pressedChangedHandler = { _, _, pressed in
            self.handleKick(value: pressed ? 1.0 : 0.0)
        }

        gamepad.buttonB.pressedChangedHandler = { _, _, pressed in
            self.handleKick(value: pressed ? 1.0 : 0.0)
        }

        gamepad.buttonX.pressedChangedHandler = { _, _, pressed in
            self.handleKick(value: pressed ? 1.0 : 0.0)
        }

        gamepad.buttonY.pressedChangedHandler = { _, _, pressed in
            self.handleKick(value: pressed ? 1.0 : 0.0)
        }

        // MARK: D-Pad (LEFT SIDE → Hi-Hat)
        gamepad.dpad.valueChangedHandler = { _, x, y in
            let value = max(abs(x), abs(y))
            self.handleHiHat(value: value)
        }

        // MARK: Thumbsticks
        gamepad.leftThumbstick.valueChangedHandler = { _, x, y in
            let value = max(abs(x), abs(y))
            self.handleHiHat(value: value)
        }

        gamepad.rightThumbstick.valueChangedHandler = { _, x, y in
            let value = max(abs(x), abs(y))
            self.handleKick(value: value)
        }

        // Intentionally ignoring:
        // - buttonMenu
        // - buttonOptions
        // - buttonHome

        print("🥁 Controller connected: \(controller.vendorName ?? "Unknown")")
    }
    
    private func remove(_ controller: GCController) {
        connectedControllers.removeAll { $0 === controller }
        isControllerConnected = !connectedControllers.isEmpty

        print("🔌 Controller disconnected: \(controller.vendorName ?? "Unknown")")
    }
    
    @MainActor
    private func handleHiHat(value: Float) {
        let now = CACurrentMediaTime()
        let distance = 1 - value

        let deltaDistance = lastHiHatDistance - distance
        let deltaTime = max(now - lastHiHatTime, 0.001)

        let velocity = deltaDistance / Float(deltaTime)

        lastHiHatDistance = distance
        lastHiHatTime = now

        hiHatPedalDistance = distance

        let isClosed = distance == 0.0
        if isClosed && !isHiHatClosed {
            isHiHatClosed = true
            hiHatVelocity = velocity
        } else if !isClosed && isHiHatClosed {
            isHiHatClosed = false
        }
    }

    @MainActor
    private func handleKick(value: Float) {
        let now = CACurrentMediaTime()
        let distance = 1 - value

        let deltaDistance = lastKickDistance - distance
        let deltaTime = max(now - lastKickTime, 0.001)

        let velocity = deltaDistance / Float(deltaTime)

        lastKickDistance = distance
        lastKickTime = now

        kickPedalDistance = distance

        let isHit = distance == 0.0
        if isHit && !isKickHit {
            isKickHit = true
            kickVelocity = velocity
        } else if !isHit && isKickHit {
            isKickHit = false
        }
    }

}
