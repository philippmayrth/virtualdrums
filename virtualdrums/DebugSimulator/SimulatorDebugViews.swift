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
            Text("Key: \(appState.simulator.simDebugLastKey)")
            Text("Hi-Hat is: \((appState.drumController?.isHiHatClosed ?? false) ? "closed" : "open")")
            Text("Hit Count: \(appState.simulator.simDebugHitCount)")
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }
}

#endif // targetEnvironment(simulator)
