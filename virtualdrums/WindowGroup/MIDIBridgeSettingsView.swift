//
//  MIDIBridgeSettingsView.swift
//  virtualdrums
//
//  Settings for MIDI bridge connection
//

import SwiftUI

struct MIDIBridgeSettingsView: View {
    @State private var bridgeURL: String = MIDIBridgeClient.shared.baseURL
    @State private var isEnabled: Bool = MIDIBridgeClient.shared.isEnabled
    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var statusMessage: String = ""
    
    enum ConnectionStatus {
        case unknown, checking, connected, failed
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    statusIndicator
                }
                
                Button(action: checkConnection) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Test Connection")
                    }
                }
                .disabled(connectionStatus == .checking)
            } header: {
                Text("Connection")
            }
            
            Section {
                Toggle("Enable MIDI Bridge", isOn: $isEnabled)
                    .onChange(of: isEnabled) { oldValue, newValue in
                        MIDIBridgeClient.shared.isEnabled = newValue
                    }
                
                HStack {
                    Text("Server URL")
                    Spacer()
                    TextField("URL", text: $bridgeURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                Button("Save URL") {
                    MIDIBridgeClient.shared.baseURL = bridgeURL
                    checkConnection()
                }
            } header: {
                Text("Settings")
            }
            
            Section {
                Text("The MIDI Bridge converts VR drum hits into MIDI messages for Logic Pro and other DAWs.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("To start the bridge, run:\n\ncd midi_bridge\npipenv run python app.py")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("MIDI Bridge")
        .onAppear {
            checkConnection()
        }
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            switch connectionStatus {
            case .unknown:
                Image(systemName: "circle.fill")
                    .foregroundColor(.gray)
                Text("Unknown")
            case .checking:
                ProgressView()
                    .scaleEffect(0.8)
                Text("Checking...")
            case .connected:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Connected")
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("Failed")
            }
        }
        .font(.caption)
    }
    
    private func checkConnection() {
        connectionStatus = .checking
        statusMessage = ""
        
        Task {
            do {
                let response = try await MIDIBridgeClient.shared.checkHealth()
                await MainActor.run {
                    connectionStatus = .connected
                    if let status = response["status"] as? String,
                       let port = response["midi_port"] as? String {
                        statusMessage = "Connected to \(port)"
                    }
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .failed
                    statusMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MIDIBridgeSettingsView()
    }
}
