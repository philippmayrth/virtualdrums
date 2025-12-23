import SwiftUI
import Combine

#if targetEnvironment(simulator)
@MainActor
final class SimulatorState: ObservableObject {
    @Published var simulatorStickMoveDelta: SIMD3<Float> = .zero
    @Published var simulatorStickMoveToken: Int = 0
    @Published var simulatorStickResetToken: Int = 0
    @Published var simulatorStickSweepToken: Int = 0
    @Published var simDebugLastEvent: String = "-"
    @Published var simDebugLastResult: String = "-"
    @Published var simDebugLastDrum: String = "-"
    @Published var simDebugLastStick: String = "-"
    @Published var simDebugHitCount: Int = 0
    @Published var simDebugLastKey: String = "-"
    @Published var simDebugLastKeyModifiers: String = "-"
    @Published var simDebugLastKeyPhase: String = "-"
    @Published var simDebugLastKeySource: String = "-"
    @Published var simDebugKeyCount: Int = 0
    @Published var simDebugKeyLog: [String] = []
}
#endif // targetEnvironment(simulator)
