//
//  ContentView.swift
//  virtualdrums
//
//  Created by Passion on 23.10.25.
//

import SwiftUI
import RealityKit
import RealityKitContent

private struct DrumKit: Identifiable {
    let id: DrumKitID
    let label: String
    let description: String

    static let accoustic = DrumKit(
        id: .accoustic,
        label: "Accoustic Kit",
        description: "Natural sounds with warm resonance and dynamic feel"
    )
    static let electronic = DrumKit(
        id: .electronic,
        label: "Electronic Kit",
        description: "Textured sounds with controlled grit and clarity"
    )
    static let alternative = DrumKit(
        id: .alternative,
        label: "Alternative Kit",
        description: "Tight, compressed drum sounds"
    )
    
    /// Collection for looping
    static let all: [DrumKit] = [.accoustic, .electronic, .alternative]
}

struct DrumKitView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject var appState: AppState

    private func isSelected(_ kitID: DrumKitID) -> Bool {
        return appState.selectedDrumKit == kitID
    }
    
    var body: some View {
        VStack(spacing: 30) {
            
            VStack {
                Text("Sound Kits")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select a kit to change the sound of your drums!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            // Drum kit selection buttons
            VStack() {
                ForEach(DrumKit.all) { kit in
                    if isSelected(kit.id) {
                        DrumKitButton(
                            kit: kit,
                            appState: appState,
                            openImmersiveSpace: openImmersiveSpace
                        )
                        .buttonStyle(.borderless)
                        .disabled(true)
                    } else {
                        DrumKitButton(
                            kit: kit,
                            appState: appState,
                            openImmersiveSpace: openImmersiveSpace
                        )
                    }
                }
            }
        }
        .padding(60)
    }
}

/// Reusable drum kit button component
private struct DrumKitButton: View {
    let kit: DrumKit
    @ObservedObject var appState: AppState    
    let openImmersiveSpace: OpenImmersiveSpaceAction
    
    var body: some View {
        Button {
            Task {
                appState.selectedDrumKit = kit.id
                if !appState.isImmersiveSpaceOpen {
                    await openImmersiveSpace(id: "drum-volume")
                }
            }
        } label: {
            HStack {
                Text("🎶")
                    .font(.system(size: 40))
                VStack(alignment: .leading) {
                    Text(kit.label)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(kit.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    DrumKitView()
        .environmentObject(AppState())
}
