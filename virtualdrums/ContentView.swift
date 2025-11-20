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
            Text("Select Your Drum Kit")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("Choose a kit to play in VR")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Drum kit selection buttons
            VStack(spacing: 20) {
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
            .padding()
            
            Spacer()
            
            // Preview
            Model3D(named: "DrumKit_Named", bundle: .main)
                .frame(width: 250, height: 250)
            
            Text("Tap a drum kit to enter VR")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .padding()
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(kit.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(kit.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(kit.pieces.count) drums")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(AppState())
}
