//
//  DrumSetView.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 17.12.25.
//

import SwiftUI

private struct DrumSet: Identifiable {
    let id: DrumSetID
    let label: String
    let description: String

    static let natal = DrumSet(
        id: .natal,
        label: "Natal Drum",
        description: "5 drums, 3 cymbals"
    )
    static let opal = DrumSet(
        id: .opal,
        label: "Opal Drum",
        description: "5 drums , 3 cymbals"
    )
    
    /// Collection for looping
    static let all: [DrumSet] = [.natal, .opal]
}

struct DrumSetView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @State private var isAdjusting: Bool = false

    var body: some View {
        Group() {
            if isAdjusting {
                AdjustmentView(
                    appState: appState,
                    isAdjusting: $isAdjusting
                )
            } else {
                DrumSetSelection(
                    appState: appState,
                    openImmersiveSpace: openImmersiveSpace,
                    isAdjusting: $isAdjusting
                )
            }
        }
        .padding(60)
    }
}

private struct DrumSetSelection: View {
    @ObservedObject var appState: AppState
    let openImmersiveSpace: OpenImmersiveSpaceAction
    @Binding var isAdjusting: Bool
    
    private func isSelected(_ drumSetID: DrumSetID) -> Bool {
        return appState.selectedDrumSet == drumSetID && appState.isImmersiveSpaceOpen
    }

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
            
            VStack(spacing: 8) {
                // Drum set selection buttons
                ForEach(DrumSet.all) { set in
                    if isSelected(set.id) {
                        DrumSetButton(
                            set: set,
                            appState: appState,
                            openImmersiveSpace: openImmersiveSpace
                        )
                        .buttonStyle(.borderless)
                        .disabled(true)
                    } else {
                        DrumSetButton(
                            set: set,
                            appState: appState,
                            openImmersiveSpace: openImmersiveSpace
                        )
                    }
                }
            }
         
            Button(action: {
                isAdjusting = true
            }) {
                Label("Adjust", systemImage: "pencil")
            }
            .disabled(!appState.isImmersiveSpaceOpen)
            .opacity(appState.isImmersiveSpaceOpen ? 1 : 0)
            
        }
    }
}

//// Reusable drum set button component
private struct DrumSetButton: View {
    let set: DrumSet
    @ObservedObject var appState: AppState
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
