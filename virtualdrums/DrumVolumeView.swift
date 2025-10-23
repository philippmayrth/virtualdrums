import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

struct DrumVolumeView: View {
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
