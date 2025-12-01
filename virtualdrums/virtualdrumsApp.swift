//
//  virtualdrumsApp.swift
//  virtualdrums
//
//  Created by Passion on 23.10.25.
//

import SwiftUI

@main
struct virtualdrumsApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: "drum-volume") {
            DrumVolumeView()
                .environmentObject(appState)
                .onAppear {
                    appState.isImmersiveSpaceOpen = true
                }
                .onDisappear {
                    appState.isImmersiveSpaceOpen = false
                }
        }
    }
}
