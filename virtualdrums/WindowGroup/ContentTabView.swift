//
//  TabView.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 17.12.25.
//

import SwiftUI

struct ContentTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            DrumSetView()
                .environmentObject(appState)
                .tabItem {
                    Label {
                        Text("Drums")
                    } icon: {
                        Image("drum_set")
                    }
                }

            DrumKitView()
                .environmentObject(appState)
                .tabItem {
                    Label("Sounds", systemImage: "music.note.square.stack.fill")
                }
            
            FootPedalView()
                .tabItem {
                    Label {
                        Text("Pedals")
                    } icon: {
                        Image("foot_pedal")
                    }
                }

            CreditsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Credits", systemImage: "info.circle")
                }

            #if targetEnvironment(simulator)
            SimulatorDebugTab()
                .environmentObject(appState)
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
            #endif // targetEnvironment(simulator)
        }
    }
}

#Preview {
    ContentTabView()
}


