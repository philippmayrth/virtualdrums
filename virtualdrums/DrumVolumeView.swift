import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation
import CoreMIDI

class MIDIManager {
    private var client = MIDIClientRef()
    private var outPort = MIDIPortRef()
    private var destination: MIDIEndpointRef? = nil
    
    init() {
        MIDIClientCreate("VirtualDrumsMIDIClient" as CFString, nil, nil, &client)
        MIDIOutputPortCreate(client, "VirtualDrumsOutPort" as CFString, &outPort)
        // Use the first available destination
        let destCount = MIDIGetNumberOfDestinations()
        if destCount > 0 {
            destination = MIDIGetDestination(0)
        } else {
            print("No MIDI destinations available.")
        }
    }
    
    func sendNoteOn(note: UInt8 = 60, velocity: UInt8 = 100, channel: UInt8 = 9) {
        #if targetEnvironment(simulator)
        print("[SIMULATOR] MIDI Note On - note: \(note), velocity: \(velocity), channel: \(channel)")
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
}

struct DrumVolumeView: View {
    @State private var message: String = "Touch the drum!"
    @State private var audioPlayer: AVAudioPlayer? = nil
    private let midiManager = MIDIManager()
    
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
                        midiManager.sendNoteOn(note: 36, velocity: 120, channel: 0) // MIDI note 36 = Bass Drum
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
        //  test sound source https://cdn.pixabay.com/download/audio/2025/10/16/audio_3098f90d3e.mp3?filename=808-bass-drum-421219.mp3
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

#Preview {
    DrumVolumeView()
}
