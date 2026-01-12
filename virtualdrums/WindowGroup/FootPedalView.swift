import SwiftUI
import RealityKit
import RealityKitContent

struct FootPedalView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject var appState: AppState
    @StateObject private var pedal = FootPedalManager.shared    

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                headerSection
                descriptionSection
                connectionSection
                mappingSection
                supportedControllersSection

            }
            .padding(30)
        }
    }
}

private extension FootPedalView {
    var headerSection: some View {
        Text("Game Controller as Foot Pedal")
            .font(.largeTitle)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}


private extension FootPedalView {
    var connectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if pedal.isControllerConnected {
                ForEach(pedal.controllerNames, id: \.self) { name in
                    statusRow(text: "\(name) connected", color: .green)
                }
            } else {
                statusRow(text: "No controller connected", color: .red)
            }
        }
    }

    func statusRow(text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(text)
                .foregroundColor(.secondary)
        }
    }
}


private extension FootPedalView {
    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By default, the kick is played with a drum stick and the hi-hat with tap gestures.")

            Text("Optionally, a physical game controller can be used to control the foot pedals instead.")

        }
    }
}


private extension FootPedalView {
    var mappingSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("All left-side controls operate the hi-hat, all right-side controls the kick.")
                .font(.callout)
            
            Divider()
            
            mappingRow(
                title: "Hi-Hat",
                content:
                    """
                    Left Thumbstick (any direction)
                    Left Trigger (L2)
                    Left Shoulder (L1)
                    D-Pad (any direction)
                    """
            )

            Divider()

            mappingRow(
                title: "Kick",
                content:
                    """
                    Right Thumbstick (any direction)
                    Right Trigger (R2)
                    Right Shoulder (R1)
                    Button A, B, X, Y
                    """
            )
            
            Divider()
            
            Text("Triggers and thumbsticks are recommended, as they respond continuously to how far you press.")
                .font(.callout)
            
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .foregroundColor(.white)
    }

    func mappingRow(title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(title)
                .fontWeight(.bold)
                .frame(width: 80, alignment: .leading)

            Text(content)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.callout)
    }
}


private extension FootPedalView {
    var supportedControllersSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Supported Controllers")
                .font(.title)
                .fontWeight(.bold)

            Group {
                Text("This app uses Apple’s GameController framework and supports any device that conforms to the GCExtendedGamepad profile.")

                Text("This includes commercial controllers (PS, Xbox, Switch) as well as custom-built pedals that emulate a HID gamepad.")

                Text("Analog inputs are recommended, such as triggers or thumbsticks, as they report continuous values.")

                Text("Custom pedals behave exactly like standard controller inputs and require no special configuration.")

                Text("We are working on instructions for 3D-printed pedal adapters and custom microcontroller-based pedals. Contributions are welcome.")
            }
            .foregroundColor(.secondary)
        }
    }
}
