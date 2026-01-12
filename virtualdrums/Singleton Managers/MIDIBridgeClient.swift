//
//  MIDIBridgeClient.swift
//  virtualdrums
//
//  Sends drum events to Python MIDI bridge
//

import Foundation

/// HTTP client for communicating with the MIDI Bridge server
class MIDIBridgeClient {
    
    // MARK: - Singleton
    
    static let shared = MIDIBridgeClient()
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Bridge server URL (update with your Mac's IP if needed)
    var baseURL = "http://localhost:5729"
    
    /// Enable/disable bridge communication
    var isEnabled = true
    
    // MARK: - Public API
    
    /// Send a drum hit event to the bridge
    func sendDrumHit(drum: DrumID, velocity: Float, noteOffDelay: Float = 0.1) {
        guard isEnabled else { return }
        
        Task {
            do {
                let payload: [String: Any] = [
                    "drum": drum.rawValue,
                    "velocity": velocity,
                    "noteOffDelay": noteOffDelay
                ]
                
                try await post(endpoint: "/event", payload: payload)
                print("📡 Sent to bridge: \(drum.rawValue) (vel: \(velocity))")
            } catch {
                print("⚠️ Bridge communication error: \(error)")
            }
        }
    }
    
    /// Send kit selection change to the bridge
    func sendKitSelection(drumKit: DrumKitID? = nil, soundKit: DrumSetID? = nil) {
        guard isEnabled else { return }
        
        Task {
            do {
                var payload: [String: Any] = [:]
                
                if let drumKit = drumKit {
                    payload["drumkit"] = drumKit.rawValue
                }
                
                if let soundKit = soundKit {
                    payload["soundkit"] = soundKit.rawValue
                }
                
                guard !payload.isEmpty else { return }
                
                try await post(endpoint: "/select", payload: payload)
                print("📡 Sent selection to bridge: \(payload)")
            } catch {
                print("⚠️ Bridge communication error: \(error)")
            }
        }
    }
    
    /// Check if the bridge server is reachable
    func checkHealth() async throws -> [String: Any] {
        let url = URL(string: "\(baseURL)/health")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BridgeError.serverError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BridgeError.invalidResponse
        }
        
        return json
    }
    
    // MARK: - Private Helpers
    
    private func post(endpoint: String, payload: [String: Any]) async throws {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BridgeError.serverError
        }
    }
    
    // MARK: - Error Types
    
    enum BridgeError: Error {
        case serverError
        case invalidResponse
        case networkError
    }
}
