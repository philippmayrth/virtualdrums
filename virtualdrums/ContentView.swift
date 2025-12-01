//
//  ContentView.swift
//  virtualdrums
//
//  Created by Passion on 23.10.25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 30) {
            
            VStack {
                Text("Drum Sound Kits")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select a kit to change the sound of your drums!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            
            // Drum kit selection buttons
            VStack() {
                DrumKitButton(
                    kitName: "bite",
                    kit: DrumKit.bite,
                    appState: appState,
                    openImmersiveSpace: openImmersiveSpace
                )
                
                DrumKitButton(
                    kitName: "kick",
                    kit: DrumKit.kick,
                    appState: appState,
                    openImmersiveSpace: openImmersiveSpace
                )
                
                DrumKitButton(
                    kitName: "squeeze",
                    kit: DrumKit.squeeze,
                    appState: appState,
                    openImmersiveSpace: openImmersiveSpace
                )
            }

//            // Preview
//            Model3D(named: "DrumKit_Named", bundle: .main)
//                .frame(width: 250, height: 250)
            
//            Text("Tap a drum kit to enter VR")
//                .font(.caption)
//                .foregroundColor(.secondary)
//                .padding(.bottom, 20)

        }
        .padding(60)
        .fixedSize()
    }
}

/// Reusable drum kit button component
struct DrumKitButton: View {
    let kitName: String
    let kit: DrumKit
    let appState: AppState
    let openImmersiveSpace: OpenImmersiveSpaceAction
    
    var body: some View {
        Button {
            Task {
                appState.selectedDrumKitName = kitName
                await openImmersiveSpace(id: "drum-volume")
            }
        } label: {
            HStack {
                Text("🥁")
                    .font(.system(size: 40))
                VStack(alignment: .leading) {
                    Text(kit.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    HStack {
                        Text(kit.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(kit.pieces.count) drums")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 25)
                    }
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(AppState())
}
