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
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            
            Group {
                if appState.isProjekttag {
                    ProjekttagView()
                        .environmentObject(appState)
                        
                } else {
                    ContentTabView()
                        .environmentObject(appState)
                        .frame(minWidth: Config.tabViewWidth, maxWidth: Config.tabViewWidth,
                               minHeight: Config.tabViewHeight, maxHeight: Config.tabViewHeight)
                }
            }

                    .onAppear { FootPedalManager.shared.startListening() }
                    /// Routes gamepad input directly to GCController handlers instead of to focused UI/InputTargets.
                    .handlesGameControllerEvents(matching: .gamepad)
            
        }
        .onChange(of: scenePhase, { _, newPhase in
                    switch newPhase {
                    case .active:
                        print("App active")

                    case .inactive:
                        print("App inactive (about to background / quit)")

                    case .background:
                        print("App in background — save state here")


                    @unknown default:
                        break
                    }
                })
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: "drum-volume") {
            ImmersiveView()
                .environmentObject(appState)
                .onAppear { appState.isImmersiveSpaceOpen = true }
                .onDisappear { appState.isImmersiveSpaceOpen = false }
                /// Routes gamepad input directly to GCController handlers instead of to focused UI/InputTargets.
                .handlesGameControllerEvents(matching: .gamepad)
        }
        .environmentObject(appState)
    }
}
