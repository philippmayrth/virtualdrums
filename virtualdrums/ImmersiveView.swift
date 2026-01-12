import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation
import ARKit

struct ImmersiveView: View {
    
    @EnvironmentObject var appState: AppState
    @StateObject private var footPedalManager = FootPedalManager.shared
    @StateObject private var viewModel = ImmersiveViewModel()

    var body: some View {
        RealityView { content in
            await viewModel.setup(content: content, appState: appState)
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in viewModel.onTapGesture(value: value) }
        )
        .onChange(of: appState.selectedDrumSet, { _, drumSet in
            viewModel.onChangeDrumSet(to: drumSet)
        })
        .onChange(of: footPedalManager.hiHat.distance, {_, newDistance in
            viewModel.onChangeHiHatTopPosition(to: newDistance)
        })
        .onChange(of: footPedalManager.kick.distance, {oldDistance, newDistance in
            viewModel.onChangeKickBeaterPosition(from: oldDistance, to: newDistance)
        })
        .onChange(of: footPedalManager.isControllerConnected, {_, isConnected in
            viewModel.onChangeControllerConnected(isConnected)
        })
        #if targetEnvironment(simulator)
        .onChange(of: appState.simulator.simulatorStickMoveToken, { _, _ in
            let delta = appState.simulator.simulatorStickMoveDelta
            viewModel.moveSimulatorStick(dx: delta.x, dy: delta.y, dz: delta.z)
        })
        .onChange(of: appState.simulator.simulatorStickResetToken, { _, _ in
            viewModel.resetSimulatorStick()
        })
        .onChange(of: appState.simulator.simulatorStickSweepToken, { _, _ in
            viewModel.startSimulatorSweep(at: viewModel.simulatorStickPosition)
        })
        #endif // targetEnvironment(simulator)
    }
}
