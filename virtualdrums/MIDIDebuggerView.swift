import SwiftUI
import Combine

class MIDIMessageLog: ObservableObject {
    struct MIDIMessage: Identifiable {
        let id = UUID()
        let timestamp: Date
        let description: String
    }
    @Published var messages: [MIDIMessage] = []
    
    func log(_ description: String) {
        DispatchQueue.main.async {
            self.messages.insert(MIDIMessage(timestamp: Date(), description: description), at: 0)
            if self.messages.count > 100 {
                self.messages.removeLast()
            }
        }
    }
}

struct MIDIDebuggerView: View {
    @ObservedObject var log: MIDIMessageLog
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            List(log.messages) { msg in
                VStack(alignment: .leading) {
                    Text(msg.description)
                        .font(.system(.body, design: .monospaced))
                    Text("\(msg.timestamp, formatter: dateFormatter)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("MIDI Debugger")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") { log.messages.removeAll() }
                }
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "HH:mm:ss.SSS"
    return df
}()
