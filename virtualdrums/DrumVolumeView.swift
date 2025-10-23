//
//  DrumVolumeView.swift
//  virtualdrums
//
//  Created by Passion on 23.10.25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation
import CoreMIDI

class MIDIManager {
    private var client = MIDIClientRef()
    private var outPort = MIDIPortRef()
    private var inPort = MIDIPortRef()
    private var destination: MIDIEndpointRef? = nil
    private var log: MIDIMessageLog?
    
    init(log: MIDIMessageLog? = nil) {
        self.log = log
        MIDIClientCreate("VirtualDrumsMIDIClient" as CFString, nil, nil, &client)
        MIDIOutputPortCreate(client, "VirtualDrumsOutPort" as CFString, &outPort)
        MIDIInputPortCreate(client, "VirtualDrumsInPort" as CFString, midiInputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &inPort)
        // Use the first available destination
        let destCount = MIDIGetNumberOfDestinations()
        if destCount > 0 {
            destination = MIDIGetDestination(0)
        } else {
            print("No MIDI destinations available.")
        }
        // Connect to all sources
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let src = MIDIGetSource(i)
            MIDIPortConnectSource(inPort, src, nil)
        }
    }
    
    func sendNoteOn(note: UInt8 = 60, velocity: UInt8 = 100, channel: UInt8 = 9) {
        let msg = "Note On - note: \(note), velocity: \(velocity), channel: \(channel)"
        log?.appendFromMIDIStack("[OUT] " + msg)
        #if targetEnvironment(simulator)
        print("[SIMULATOR] \(msg)")
        #else
        guard let destination = destination else { return }
        var packet = MIDIPacket()
        packet.timeStamp = 0
        packet.length = 3
        packet.data.0 = 0x90 | (channel & 0x0F) // Note On, channel
        packet.data.1 = note // MIDI note number
        packet.data.2 = velocity // Velocity
        var packetList = MIDIPacketList(numPackets: 1, packet: packet)
        withUnsafePointer(to: &packetList) { ptr in
            let rawPtr = UnsafeRawPointer(ptr)
            let midiPtr = rawPtr.bindMemory(to: MIDIPacketList.self, capacity: 1)
            MIDISend(outPort, destination, midiPtr)
        }
        #endif
    }

    // MIDI input callback
    private let midiInputCallback: MIDIReadProc = { (pktList, refCon, srcConnRefCon) in
        let manager = Unmanaged<MIDIManager>.fromOpaque(refCon!).takeUnretainedValue()
        let packetList = pktList.pointee
        // Correctly get a mutable pointer to the first packet
        var packet = UnsafeMutableRawPointer(mutating: pktList).assumingMemoryBound(to: MIDIPacket.self)
        for _ in 0..<packetList.numPackets {
            let length = Int(packet.pointee.length)
            let data = withUnsafeBytes(of: packet.pointee.data) { rawPtr in
                Array(rawPtr.prefix(length))
            }
            let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            let msg = "[IN] MIDI Packet: [\(hex)]"
            manager.log?.appendFromMIDIStack(msg)
            packet = MIDIPacketNext(packet)
        }
    }
}

struct DrumVolumeView: View {
    var midiManager: MIDIManager
    @State private var message: String = "Touch the drum!"
    @State private var audioPlayer: AVAudioPlayer? = nil
    
    var body: some View {
        ZStack {
            RealityView { content in
                do {
                    let entity = try await Entity(named: "Scene", in: realityKitContentBundle)
                    entity.generateCollisionShapes(recursive: true)
                    entity.components.set(InputTargetComponent())
                    let anchor = AnchorEntity(world: [0, 1.5, -2])
                    anchor.addChild(entity)
                    content.add(anchor)
                } catch {
                    print("Failed to load model: \(error)")
                }
            }
            .gesture(
                TapGesture()
                    .onEnded {
                        message = "Drum tapped!"
                        playDrumSound()
                        midiManager.sendNoteOn(note: 36, velocity: 120, channel: 0)
                        print("Drum entity tapped!")
                    }
            )
            .ignoresSafeArea()
        }
        .overlay(
            Text(message)
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(),
            alignment: .top
        )
        .onAppear {
            prepareDrumSound()
        }
    }
    
    private func prepareDrumSound() {
        if let url = Bundle.main.url(forResource: "808-bass-drum-421219", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error loading 808-bass-drum-421219.mp3: \(error)")
            }
        } else {
            print("808-bass-drum-421219.mp3 not found in bundle.")
        }
    }
    
    private func playDrumSound() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
}

// End of DrumVolumeView and MIDIManager definitions.
