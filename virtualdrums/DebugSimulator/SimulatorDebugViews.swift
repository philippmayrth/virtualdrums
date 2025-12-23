import SwiftUI

#if targetEnvironment(simulator)
struct SimulatorDebugTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Debug Output")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Keyboard Mode: \(appState.keyboardInputMode.label)")
                    .font(.caption)
                SimulatorStickControlPanel()
                    .environmentObject(appState)
                SimulatorDebugPanel()
                    .environmentObject(appState)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}

private struct SimulatorDebugPanel: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Debug")
                .font(.subheadline)
            Text("Event: \(appState.simulator.simDebugLastEvent)")
            Text("Result: \(appState.simulator.simDebugLastResult)")
            Text("Drum: \(appState.simulator.simDebugLastDrum)")
            Text("Stick: \(appState.simulator.simDebugLastStick)")
            Text("Key: \(appState.simulator.simDebugLastKey)  Mods: \(appState.simulator.simDebugLastKeyModifiers)")
            Text("Key Phase: \(appState.simulator.simDebugLastKeyPhase)  Key Count: \(appState.simulator.simDebugKeyCount)")
            Text("Key Source: \(appState.simulator.simDebugLastKeySource)")
            Text("Hi-Hat Pedal: \(appState.hiHatPedalIsClosed ? "closed" : "open")")
            Text("Hi-Hat Output: \(hiHatOutputLabel)")
            Text("Hit Count: \(appState.simulator.simDebugHitCount)")
            Text("Key Log")
                .font(.caption)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if appState.simulator.simDebugKeyLog.isEmpty {
                        Text("No key input yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(appState.simulator.simDebugKeyLog.indices, id: \.self) { index in
                            Text(appState.simulator.simDebugKeyLog[index])
                                .font(.caption2)
                                .monospaced()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 120)
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private var hiHatOutputLabel: String {
        appState.hiHatPedalIsClosed ? "bass drum (placeholder)" : "hi-hat"
    }
}

#endif // targetEnvironment(simulator)
