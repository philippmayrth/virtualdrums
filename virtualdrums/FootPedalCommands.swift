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
                appState.drumController?.hitDrum(drum: .target_bass_drum)
            }
            .keyboardShortcut(.space, modifiers: [])

            Button("Hi-Hat Hit") {
                appState.drumController?.hitDrum(drum: .target_hi_hat)
            }
            .keyboardShortcut(.return, modifiers: [])
            
            Button("Hi-Hat Open/Close") {
                appState.drumController?.toggleHiHat()
            }
            .keyboardShortcut(.delete, modifiers: [])
        }
    }
}
