import SwiftUI

// MARK: - Combined View

struct AdjustmentView: View {
    @ObservedObject var appState: AppState
    @Binding var isAdjusting: Bool

    var body: some View {
        VStack(spacing: 15) {
            
            Picker("Handedness", selection: $appState.handedness) {
                ForEach(Handedness.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
                        
            VStack(spacing: 14) {
                LabeledSlider(
                    title: "Stick Length",
                    axisHint: "Short – Long",
                    value: $appState.stickHandleLength,
                    range: 0.05...1.5
                )

                LabeledSlider(
                    title: "Drum Size",
                    axisHint: "Small – Large",
                    value: $appState.drumScale,
                    range: 0.2...2.5
                )

                LabeledSlider(
                    title: "Drum Distance",
                    axisHint: "Near – Far",
                    value: $appState.drumDistance,
                    range: -2.0...2.0
                )

                LabeledSlider(
                    title: "Drum Height",
                    axisHint: "Low – High",
                    value: $appState.drumHeight,
                    range: -2.0...2.0
                )
            }
            
            HStack(spacing: 12) {
                Button {
                    appState.stickHandleLength = Config.initialStickHandleLength
                    appState.drumScale = 1
                    appState.drumDistance = 0
                    appState.drumHeight = 0
                    appState.handedness = .right
                } label: {
                    Text("Reset")
                        .frame(maxWidth: .infinity)
                }
                Button {
                    isAdjusting = false
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                }
                .tint(.accentColor)
            }
            .padding(.top, 10)
        }
    }
}

private struct LabeledSlider: View {
    let title: String
    let axisHint: String
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(axisHint)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(value, format: .number.precision(.fractionLength(2)))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: range)
        }
    }
}
