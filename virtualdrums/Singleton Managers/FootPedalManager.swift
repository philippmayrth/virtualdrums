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
        var distance: Float = 1.0
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
    
    // MARK: - Controller Mapping
    
    /// Maps a standard game controller to two virtual drum pedals.
    /// The controller is split into left and right halves: the left side inputs control the Hi-Hat pedal and the right side inputs control the kick pedal.

    private func attach(_ controller: GCController) {
        guard let gamepad = controller.extendedGamepad else { return }
        guard !connectedControllers.contains(where: { $0 === controller }) else { return } // prevent duplicates
        
        connectedControllers.append(controller)
        isControllerConnected = true
        
        // LEFT SIDE BUTTONS → HI-HAT

        if (controller.vendorName == "DUALSHOCK 4 Wireless Controller") {
            gamepad.leftTrigger.valueChangedHandler = { _, value, _ in
                self.update(&self.kick, value: value)
            }

            gamepad.leftShoulder.pressedChangedHandler = { _, _, pressed in
                self.update(&self.kick, value: pressed ? 1 : 0)
            }

            gamepad.dpad.valueChangedHandler = { _, x, y in
                self.update(&self.kick, value: max(abs(x), abs(y)))
            }

            gamepad.leftThumbstick.valueChangedHandler = { _, x, y in
                self.update(&self.kick, value: max(abs(x), abs(y)))
            }

            // RIGHT SIDE BUTTONS → KICK

            gamepad.rightTrigger.valueChangedHandler = { _, value, _ in
                self.update(&self.hiHat, value: value)
            }

            gamepad.rightShoulder.pressedChangedHandler = { _, _, pressed in
                self.update(&self.hiHat, value: pressed ? 1 : 0)
            }

            gamepad.buttonA.pressedChangedHandler = { _, _, pressed in
                self.update(&self.hiHat, value: pressed ? 1 : 0)
            }

            gamepad.buttonB.pressedChangedHandler = { _, _, pressed in
                self.update(&self.hiHat, value: pressed ? 1 : 0)
            }

            gamepad.buttonX.pressedChangedHandler = { _, _, pressed in
                self.update(&self.hiHat, value: pressed ? 1 : 0)
            }

            gamepad.buttonY.pressedChangedHandler = { _, _, pressed in
                self.update(&self.hiHat, value: pressed ? 1 : 0)
            }

            gamepad.rightThumbstick.valueChangedHandler = { _, x, y in
                self.update(&self.hiHat, value: max(abs(x), abs(y)))
            }
        } else {
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
    
    // The controller gives us "pressure" (1 = pressed).
    // We flip it into "remaining travel distance" (0 = pressed, 1 = released)
    @MainActor
    private func update(_ pedal: inout PedalState, value: Float) {
        // TODO: add velocity?
        let distance = 1 - value
        pedal.distance = distance
    }
}
