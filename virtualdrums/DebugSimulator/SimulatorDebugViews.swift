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

    // MARK: - Debug Logs Display

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
                Text("Hi-Hat is: \(appState.isHiHatClosed ? "closed" : "open")")
                Text("Hit Count: \(appState.simulator.simDebugHitCount)")
            }
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
        }
    }

    // MARK: - Debug Controls

    struct SimulatorStickControlPanel: View {
        @EnvironmentObject var appState: AppState

        private var step: Float { 0.02 }

        var body: some View {
            VStack(spacing: 10) {
                Text("Simulator Stick")
                    .font(.headline)
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        moveButton("←") { queueMove(dx: -step, dy: 0, dz: 0) }
                        moveButton("→") { queueMove(dx: step, dy: 0, dz: 0) }
                        moveButton("↑") { queueMove(dx: 0, dy: 0, dz: -step) }
                        moveButton("↓") { queueMove(dx: 0, dy: 0, dz: step) }
                    }
                    HStack(spacing: 8) {
                        moveButton("Up") { queueMove(dx: 0, dy: step, dz: 0) }
                        moveButton("Down") {
                            queueMove(dx: 0, dy: -step, dz: 0)
                        }
                        Button("Sweep") { startSweep() }
                        Button("Reset") { resetStick() }
                    }
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private func moveButton(_ title: String, action: @escaping () -> Void)
            -> some View
        {
            Button(title, action: action)
                .buttonStyle(.bordered)
        }

        private func queueMove(dx: Float, dy: Float, dz: Float) {
            appState.simulator.simulatorStickMoveDelta = [dx, dy, dz]
            appState.simulator.simulatorStickMoveToken += 1
        }

        private func resetStick() {
            appState.simulator.simulatorStickResetToken += 1
        }

        private func startSweep() {
            appState.simulator.simulatorStickSweepToken += 1
        }
    }
#endif  // targetEnvironment(simulator)
