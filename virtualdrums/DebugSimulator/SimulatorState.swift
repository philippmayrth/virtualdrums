import Combine
import SwiftUI

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

        func updateDebugKeyPressed(key: String, action: String) {
            Task { @MainActor in
                simDebugLastEvent = action
                simDebugLastKey = key
            }
        }

    }

#endif  // targetEnvironment(simulator)
