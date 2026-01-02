import RealityKit

#if targetEnvironment(simulator)
extension ImmersiveView {
    func updateDebugCollision(drumEntity: Entity, stickEntity: Entity) {
        let drumName = drumEntity.name
        let stickName = stickEntity.name
        Task { @MainActor in
            appState.simulator.simDebugLastEvent = "collision began"
            appState.simulator.simDebugLastDrum = drumName
            appState.simulator.simDebugLastStick = stickName
        }
    }

    func updateDebugHitCheck(drumName: String, stickName: String, result: String) {
        Task { @MainActor in
            appState.simulator.simDebugLastEvent = "hit check"
            appState.simulator.simDebugLastResult = result
            appState.simulator.simDebugLastDrum = drumName
            appState.simulator.simDebugLastStick = stickName
        }
    }

    func updateDebugHitAccepted(drumName: String) {
        Task { @MainActor in
            appState.simulator.simDebugLastEvent = "hit triggered"
            appState.simulator.simDebugLastResult = "drumController.hitDrum"
            appState.simulator.simDebugLastDrum = drumName
            appState.simulator.simDebugHitCount += 1
        }
    }
}
#endif // targetEnvironment(simulator)
