//
//  DrumSetView.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 17.12.25.
//

import SwiftUI

enum DrumSetID: String, CaseIterable, Identifiable {
    case drum_kit
    case burgundy_drum

    var id: String { rawValue }
}

private struct DrumSet: Identifiable {
    let id: DrumSetID
    let label: String
    let description: String

    static let drum_kit = DrumSet(
        id: .drum_kit,
        label: "Fun Drum",
        description: "5 drums, 3 cymbals"
    )
    static let burgundy_drum = DrumSet(
        id: .burgundy_drum,
        label: "Opal Drum",
        description: "5 drums , 2 cymbals"
    )
    
    /// Collection for looping
    static let all: [DrumSet] = [.drum_kit, .burgundy_drum]
}

struct DrumSetView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 30) {
            
            VStack {
                Text("Drum Sets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select the drums you'd like to play on!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            VStack(alignment: .leading, spacing: 8) {
                Toggle(
                    "Tastur Eingabe",
                    isOn: Binding(
                        get: { appState.keyboardInputMode == .textField },
                        set: { appState.keyboardInputMode = $0 ? .textField : .hardware }
                    )
                )
                .toggleStyle(.switch)
                Text(keyboardModeHint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Hi-Hat Pedal: \(appState.hiHatPedalIsClosed ? "closed" : "open")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 420, alignment: .leading)
            // Drum set selection buttons
            VStack() {
                ForEach(DrumSet.all) { set in
                    DrumSetButton(
                        set: set,
                        appState: appState,
                        openImmersiveSpace: openImmersiveSpace
                    )
                }
            }
        }
        .padding(60)
    }

    private var keyboardModeHint: String {
        switch appState.keyboardInputMode {
        case .hardware:
            return "Hardware keyboard (no on-screen keyboard). Space = bass drum, H = hi-hat hit, F = hi-hat pedal (toggle)."
        case .textField:
            return "Textfeld aktiv (on-screen keyboard). Space = bass drum, H = hi-hat hit, F = hi-hat pedal (toggle)."
        }
    }
}

//// Reusable drum set button component
private struct DrumSetButton: View {
    let set: DrumSet
    let appState: AppState
    let openImmersiveSpace: OpenImmersiveSpaceAction
    
    var body: some View {
        Button {
            Task {
                appState.selectedDrumSet = set.id
                if !appState.isImmersiveSpaceOpen {
                    await openImmersiveSpace(id: "drum-volume")
                }
            }
        } label: {
            HStack {
                Text("🥁")
                    .font(.system(size: 40))
                VStack(alignment: .leading) {
                    Text(set.label)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(set.description)
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
