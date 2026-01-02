import SwiftUI

#if targetEnvironment(simulator)
struct SimulatorStickControlPanel: View {
    @EnvironmentObject var appState: AppState

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
                    moveButton("Down") { queueMove(dx: 0, dy: -step, dz: 0) }
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

    private var step: Float { 0.02 }

    private func moveButton(_ title: String, action: @escaping () -> Void) -> some View {
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
#endif // targetEnvironment(simulator)
