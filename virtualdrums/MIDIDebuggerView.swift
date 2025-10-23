import SwiftUI
import Combine

// MIDIMessageLog now only provides an interface for appending messages from CoreMIDI callbacks.
class MIDIMessageLog: ObservableObject {
    struct MIDIMessage: Identifiable {
        let id = UUID()
        let timestamp: Date
        let description: String
    }
    @Published private(set) var messages: [MIDIMessage] = []
    
    // Only called from CoreMIDI input callback
    func appendFromMIDIStack(_ description: String) {
        DispatchQueue.main.async {
            self.messages.insert(MIDIMessage(timestamp: Date(), description: description), at: 0)
            if self.messages.count > 100 {
                self.messages.removeLast()
            }
        }
    }
    
    // Safe clear method for SwiftUI toolbar
    func clear() {
        DispatchQueue.main.async {
            self.messages.removeAll()
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
                    Button("Clear") { log.clear() }
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
