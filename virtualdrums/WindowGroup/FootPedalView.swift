//
//  FootPedalView.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 02.01.26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct FootPedalView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject var appState: AppState
    
    @StateObject private var pedal = FootPedalManager.shared

    var body: some View {
        ScrollView {

            VStack(spacing: 18) {

                Text("Foot Pedals")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 10) {
                    
                    Text(
                        "An optional way to control the kick drum and hi-hat is by using a physical game controller as pedals."
                    )
                    
                    VStack() {
                        Text(
                            "Key mapping for PS4 Controller:"
                        )

                        VStack(alignment: .center, spacing: 6) {
                            Text("Left Trigger (L2)  →  Hi-hat pedal")
                            Text("Right Trigger (R2)  →  Kick pedal")
                        }
                        .fontWeight(.bold)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.white)

                        if (pedal.isControllerConnected) {
                            ForEach(pedal.controllerNames, id: \.self) { controllerName in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(pedal.isControllerConnected ? Color.green : Color.red)
                                        .frame(width: 10, height: 10)
                                    
                                    Text(pedal.isControllerConnected ? ((controllerName) + " connected") : "No controller connected")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                            }
                        } else {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(pedal.isControllerConnected ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                
                                Text("No controller connected")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                        }
                        
                    }
                    .padding(10)
                    
                    Text("Alternatively the kick drum can also be played by striking it with a drum stick, and the hi-hat can be opened or closed using a tap gesture.")
                        .foregroundStyle(.white)

                }
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                
                    
                // MARK: - Advanced / Technical

                Text("GameControllers & Custom Pedals")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))

                VStack(spacing: 10) {
                    Text(
                        "This app uses Apple’s GameController framework to handle foot pedal input. " +
                        "Any device that presents itself as a standard game controller (HID) is supported."
                    )
                    
                    Text(
                        "This includes commercially available game controllers (e.g. Playstation) as well as custom-built foot pedals using " +
                        "microcontrollers that emulate a Bluetooth HID gamepad."
                    )

                    Text(
                        "Unlike simple button-based input, the GameController framework provides continuous trigger values " +
                        "from 0 to 1. These values represent pedal travel, allowing the app to calculate pedal speed, force, " +
                        "and hold duration."
                    )

                    Text(
                        "From the app’s perspective, a custom-built pedal behaves exactly like a standard controller trigger, " +
                        "requiring no special configuration or permissions."
                    )
                    
                    Text(
                        "This makes it possible to build custom pedals using components such as " +
                        "hall sensors, potentiometers, or load cells, while still integrating seamlessly with the app."
                    )
                }
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 600)
            .padding(40)
        }
    }

}

#Preview(windowStyle: .automatic) {
    FootPedalView()
        .environmentObject(AppState())
}
