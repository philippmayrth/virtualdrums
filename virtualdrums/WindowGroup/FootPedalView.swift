//
//  FootPedalView.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 02.01.26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct FootPedalView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 10) {

            Text("Foot Pedals")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 10) {

                wrappedText(
                    "Foot pedals are an optional alternative to the virtual sticks and floating controls. " +
                    "They let you play the kick drum and hi-hat using physical foot controllers."
                )

                sectionTitle("How It Works")

                wrappedText(
                    "The app supports physical keyboards connected via Bluetooth. " +
                    "This includes standard keyboards as well as modified or custom-built foot pedal controllers."
                )

                wrappedText(
                    "As long as the device communicates using the standard keyboard protocol, it will work."
                )

                sectionTitle("Key Mapping")

                VStack(alignment: .leading, spacing: 6) {
                    keyRow(key: "Space", action: "Play kick drum")
                    keyRow(key: "Return", action: "Play hi-hat")
                    keyRow(key: "Delete", action: "Toggle hi-hat open / closed")
                }
                .foregroundColor(.secondary)
                
            }
            .frame(maxWidth: 520)
        }
        .padding(40)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
    }

    private func wrappedText(_ text: String) -> some View {
        Text(text)
            .foregroundColor(.secondary)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func keyRow(key: String, action: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(key)
                .fontWeight(.semibold)
            Text("→ \(action)")
        }
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview(windowStyle: .automatic) {
    FootPedalView()
        .environmentObject(AppState())
}
