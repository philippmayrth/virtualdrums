import RealityKit

extension ImmersiveView {
    func updateDebugCollision(drumEntity: Entity, stickEntity: Entity) {
        #if targetEnvironment(simulator)
        let drumName = drumEntity.name
        let stickName = stickEntity.name
        Task { @MainActor in
            appState.simulator.simDebugLastEvent = "collision began"
            appState.simulator.simDebugLastDrum = drumName
            appState.simulator.simDebugLastStick = stickName
        }
        #endif // targetEnvironment(simulator)
    }

    func updateDebugHitCheck(drumName: String, stickName: String, result: String) {
        #if targetEnvironment(simulator)
        Task { @MainActor in
            appState.simulator.simDebugLastEvent = "hit check"
            appState.simulator.simDebugLastResult = result
            appState.simulator.simDebugLastDrum = drumName
            appState.simulator.simDebugLastStick = stickName
        }
        #endif // targetEnvironment(simulator)
    }

    func updateDebugHitAccepted(drumName: String) {
        #if targetEnvironment(simulator)
        Task { @MainActor in
            appState.simulator.simDebugLastEvent = "hit triggered"
            appState.simulator.simDebugLastResult = "drumController.hitDrum"
            appState.simulator.simDebugLastDrum = drumName
            appState.simulator.simDebugHitCount += 1
        }
        #endif // targetEnvironment(simulator)
    }

}
