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
        
        // Gestures
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in viewModel.onTapGesture(value: value) }
        )
        
        // App State
        .onChange(of: appState.selectedDrumSet, { _, _ in
            viewModel.onChangeDrumSet()
        })
        .onChange(of: appState.handedness, {_, _ in
            viewModel.onHandednessChanged()
        })
        .onChange(of: appState.stickHandleLength, {_, _ in
            viewModel.onStickLengthChanged()
        })
        .onChange(of: appState.drumScale, {_, _ in
            viewModel.onDrumScaleChanged()
        })
        .onChange(of: appState.drumDistance, {_, _ in
            viewModel.onDrumDistanceChanged()
        })
        .onChange(of: appState.drumHeight, {_, _ in
            viewModel.onDrumHeightChanged()
        })

        // Foot Pedal Manager
        .onChange(of: footPedalManager.hiHat.distance, {_, newDistance in
            viewModel.onChangeHiHatTopPosition(to: newDistance)
        })
        .onChange(of: footPedalManager.kick.distance, {oldDistance, newDistance in
            viewModel.onChangeKickBeaterPosition(from: oldDistance, to: newDistance)
        })
        .onChange(of: footPedalManager.isControllerConnected, {_, isConnected in
            viewModel.onChangeControllerConnected(isConnected)
        })

        // Debugging
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
