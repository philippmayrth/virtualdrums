//
//  FootPedalCommands.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 02.01.26.
//

import SwiftUI

/// Uses SwiftUI Commands so input capture works without view focus management.
struct FootPedalCommands: Commands {
    @EnvironmentObject private var appState: AppState
    
    var body: some Commands {
        CommandGroup(after: .newItem) {

            Button("Bass Drum Hit") {
                appState.drumController?.hitDrum(drum: .target_bass_drum, strikeSpeed: nil)
                
                #if targetEnvironment(simulator)
                appState.simulator.updateDebugKeyPressed(key: "space", action: "played bass_drum")
                #endif // targetEnvironment(simulator)
            }
            .keyboardShortcut(.space, modifiers: [])

            Button("Hi-Hat Hit") {
                appState.drumController?.hitDrum(drum: .target_hi_hat, strikeSpeed: nil)
                
                #if targetEnvironment(simulator)
                appState.simulator.updateDebugKeyPressed(key: "return", action: "played hi_hat (\((appState.drumController?.isHiHatClosed ?? false) ? "closed" : "open"))")
                #endif // targetEnvironment(simulator)
            }
            .keyboardShortcut(.return, modifiers: [])
            
            Button("Hi-Hat Open/Close") {
                appState.drumController?.toggleHiHat()
                
                #if targetEnvironment(simulator)
                appState.simulator.updateDebugKeyPressed(key: "return", action: "(\((appState.drumController?.isHiHatClosed ?? false) ? "closed" : "opened")) hi_hat")
                #endif // targetEnvironment(simulator)
            }
            .keyboardShortcut(.delete, modifiers: [])
        }
    }
}
