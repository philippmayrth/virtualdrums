//
//  ContentView.swift
//  virtualdrums
//
//  Created by Passion on 23.10.25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject var midiLog: MIDIMessageLog
    @State private var showDebugger = false
    var midiManager: MIDIManager

    var body: some View {
        VStack {
            Button("Place drum (just a shpere for now) in the room") {
                Task {
                    await openImmersiveSpace(id: "drum-volume")
                }
            }
            .padding(.bottom, 20)
            Button("Open MIDI Debugger") {
                showDebugger = true
            }
            .padding(.bottom, 20)
            Text("Play the drum and verify a sound plays after touching it.")
        }
        .padding()
        .sheet(isPresented: $showDebugger) {
            MIDIDebuggerView(log: midiLog)
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView(midiManager: MIDIManager(log: MIDIMessageLog()))
}
