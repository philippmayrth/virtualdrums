//
//  virtualdrumsApp.swift
//  virtualdrums
//
//  Created by Passion on 23.10.25.
//

import SwiftUI

@main
struct virtualdrumsApp: App {
    @StateObject private var midiLog = MIDIMessageLog()
    var body: some Scene {
        let midiManager = MIDIManager(log: midiLog)
        WindowGroup {
            ContentView(midiManager: midiManager)
                .environmentObject(midiLog)
        }
        ImmersiveSpace(id: "drum-volume") {
            DrumVolumeView(midiManager: midiManager)
                .environmentObject(midiLog)
        }
    }
}
