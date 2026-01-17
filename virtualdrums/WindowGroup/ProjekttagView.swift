//
//  ProjekttagView.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 16.01.26.
//

import SwiftUI
import RealityKit
import RealityKitContent

// MARK: - Drum Set Model

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
        description: "5 drums, 3 cymbals"
    )

    static let all: [DrumSet] = [.natal, .opal]
}

// MARK: - Drum Kit Model

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

    static let all: [DrumKit] = [.accoustic, .electronic, .alternative]
}

// MARK: - Combined View

struct ProjekttagView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject var appState: AppState

    @State private var controlsExpanded = true

    private func isDrumSetSelected(_ id: DrumSetID) -> Bool {
        appState.selectedDrumSet == id && appState.isImmersiveSpaceOpen
    }

    private func isDrumKitSelected(_ id: DrumKitID) -> Bool {
        appState.selectedDrumKit == id
    }
    var body: some View {
        VStack(spacing: 30) {



            VStack(spacing: 8) {
                
                Text("Drum sets")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                
                Picker("Drum Set", selection: $appState.selectedDrumSet) {
                    ForEach(DrumSet.all) { set in
                        Text(
                            "🥁 " + set.label
                                .replacingOccurrences(of: " Drum", with: "")
                        )
                        .tag(set.id)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: appState.selectedDrumSet) { _, newValue in
                    Task {
                        if !appState.isImmersiveSpaceOpen {
                            await openImmersiveSpace(id: "drum-volume")
                        }
                    }
                }

            }
            



//            // Sound Kits
//            VStack(spacing: 8) {
//                Text("Sounds kits")
//                        .font(.title2)
//                        .foregroundColor(.secondary)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                Picker("Sound Kit", selection: $appState.selectedDrumKit) {
//                    ForEach(DrumKit.all) { kit in
//                        Text(
//                            "🎶 " + kit.label
//                                .replacingOccurrences(of: " Kit", with: "")
//                        )
//                        .tag(kit.id)
//                    }
//                }
//                .pickerStyle(.segmented)
//                .onChange(of: appState.selectedDrumKit) { _, newValue in
//                    Task {
//                        if !appState.isImmersiveSpaceOpen {
//                            await openImmersiveSpace(id: "drum-volume")
//                        }
//                    }
//                }
//
//            }
            
            
            VStack(spacing: 8) {
                Text("Handedness")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                Picker("Handedness", selection: $appState.handedness) {
                    ForEach(Handedness.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .opacity(0.8)
                .padding(.top, 8)

            }
            
            
            
        
            DisclosureGroup(
                isExpanded: $controlsExpanded,
                content: {
                    ScrollView {
                        VStack(spacing: 10) {

                            LabeledSlider(
                                title: "Stick Length",
                                value: $appState.stickHandleLength,
                                range: 0.15...0.5
                            )

                            LabeledSlider(
                                title: "Drum Scale",
                                value: $appState.drumScale,
                                range: 0...2.0
                            )

                            LabeledSlider(
                                title: "Drum Distance",
                                value: $appState.drumDistance,
                                range: -1.0...1.0
                            )

                            LabeledSlider(
                                title: "Drum Height",
                                value: $appState.drumHeight,
                                range: -1.0...1.0
                            )

                           

                            Button {
                                appState.stickHandleLength = Config.stickHandleLength
                                appState.drumScale = 1
                                appState.drumDistance = 0
                                appState.drumHeight = 0
                                appState.stickTipRadius = Config.stickTipRadius
                                appState.stickHandleRadius = Config.stickHandleRadius
                                appState.handedness = .right
                            } label: {
                                Text("Reset")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                            
                            Button {
                                appState.isProjekttag = false
                            } label: {
                                Text("Open detailed view")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                        }
                        
                    }
                    .frame(maxHeight: 385)
                },
                label: {
                    HStack {
                        Text("Einstellungen")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            )
            .animation(.easeInOut(duration: 0.25), value: controlsExpanded)

            
            
        }
        
        
        
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .top)



        
    }
        

}

private struct LabeledSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(value, format: .number.precision(.fractionLength(2)))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: range)
        }
    }
}


// MARK: - Drum Set Button

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
                    .font(.system(size: 30))
                VStack(alignment: .leading) {
                    Text(set.label)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Drum Kit Button

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
                    .font(.system(size: 30))
                VStack(alignment: .leading) {
                    Text(kit.label)
                        .font(.title3)
                        .fontWeight(.semibold)

                }
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview(windowStyle: .automatic) {
    ProjekttagView()
        .environmentObject(AppState())
}
