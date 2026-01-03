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
    
    private var controller: GCController?
    
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
        // Existing controllers
        GCController.controllers().forEach { setup($0) }
        
        // New connections
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let controller = note.object as? GCController else { return }
            self?.setup(controller)
        }
    }
    
    private func setup(_ controller: GCController) {
        self.controller = controller
        
        guard let gamepad = controller.extendedGamepad else { return }
        
        // Kick drum (R2 trigger)
        gamepad.rightTrigger.valueChangedHandler = { _, value, _ in
            let now = CACurrentMediaTime()
            let distance = 1 - value

            let deltaDistance = self.lastKickDistance - distance
            let deltaTime = now - self.lastKickTime
            
            let velocity = deltaDistance / Float(deltaTime)

            self.lastKickDistance = distance
            self.lastKickTime = now

            self.kickPedalDistance = distance

            let isHit = distance == 0.0

            if isHit && !self.isKickHit {
                self.isKickHit = true
                self.kickVelocity = velocity
            }
            else if !isHit && self.isKickHit {
                self.isKickHit = false
            }
        }

        
        // Hi-hat pedal (L2 trigger)
        gamepad.leftTrigger.valueChangedHandler = { _, value, _ in
            let now = CACurrentMediaTime()
            let distance = 1 - value

            let deltaDistance = self.lastHiHatDistance - distance
            let deltaTime = now - self.lastHiHatTime

            let velocity = deltaDistance / Float(deltaTime)

            self.lastHiHatDistance = distance
            self.lastHiHatTime = now

            self.hiHatPedalDistance = distance

            let isClosed = distance == 0.0

            if isClosed && !self.isHiHatClosed {
                self.isHiHatClosed = true
                self.hiHatVelocity = velocity
                
            }
            else if !isClosed && self.isHiHatClosed {
                self.isHiHatClosed = false
            }
        }
        
        print("🥁 PS4 Drum Controller Ready")
    }
}
