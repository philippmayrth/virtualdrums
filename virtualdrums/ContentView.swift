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

    var body: some View {
        VStack {
            Button("Place 'TestCube' drum in the room") {
                Task {
                    await openImmersiveSpace(id: "drum-volume")
                }
            }
            .padding(.bottom, 20)

            // Load the TestCube model from the app's main bundle so the cube model is shown
            // instead of the default sphere placeholder that appears when the named asset
            // isn't found in the RealityKitContent bundle.
            Model3D(named: "TestCube", bundle: .main)
                .frame(width: 300, height: 300)
                .padding(.bottom, 20)

            //Model3D(named: "Scene", bundle: realityKitContentBundle)
            //.padding(.bottom, 50)

            Text("Play the drum and verify a sound plays after touching it.")
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
