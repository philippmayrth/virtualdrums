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
        ZStack {
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

                CreditsView()
                    .environmentObject(appState)
                    .tabItem {
                        Label("Credits", systemImage: "info.circle")
                    }
            }
            KeyboardCaptureOverlay()
                .environmentObject(appState)
        }
    }
}

#Preview {
    ContentTabView()
}


