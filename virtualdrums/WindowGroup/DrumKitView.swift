//
//  ContentView.swift
//  virtualdrums
//
//  Created by Passion on 23.10.25.
//

import SwiftUI
import RealityKit
import RealityKitContent

enum DrumKitID: String, CaseIterable, Identifiable {
    case bite
    case kick
    case squeeze

    var id: String { rawValue }
}

private struct DrumKit: Identifiable {
    let id: DrumKitID
    let label: String
    let description: String

    static let bite = DrumKit(
        id: .bite,
        label: "Bite Kit",
        description: "Aggressive, punchy drum sounds"
    )    
    static let kick = DrumKit(
        id: .kick,
        label: "Kick Kit",
        description: "Deep, powerful drum sounds"
    )
    static let squeeze = DrumKit(
        id: .squeeze,
        label: "Squeeze Kit",
        description: "Tight, compressed drum sounds"
    )
    
    /// Collection for looping
    static let all: [DrumKit] = [.bite, .kick, .squeeze]
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
    let appState: AppState
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
