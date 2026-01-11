//
//  virtualdrumsApp.swift
//  virtualdrums
//
//  Created by Passion on 23.10.25.
//

import SwiftUI
import GameController

@main
struct virtualdrumsApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentTabView()
                .environmentObject(appState)
                .frame(minWidth: 600, maxWidth: 600, minHeight: 450, maxHeight: 450)
                .onAppear { FootPedalManager.shared.startListening() }
                // Routes gamepad input directly to GCController handlers instead of to focused UI/InputTargets.
                .handlesGameControllerEvents(matching: .gamepad)
        }
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: "drum-volume") {
            ImmersiveView()
                .environmentObject(appState)
                .onAppear { appState.isImmersiveSpaceOpen = true }
                .onDisappear { appState.isImmersiveSpaceOpen = false }
                // Routes gamepad input directly to GCController handlers instead of to focused UI/InputTargets.
                .handlesGameControllerEvents(matching: .gamepad)
        }
        .environmentObject(appState)
    }
}
