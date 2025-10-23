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
            Button("Place drum (just a shpere for now) in the room") {
                Task {
                    await openImmersiveSpace(id: "drum-volume")
                }
            }
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
