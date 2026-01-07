//
//  InfoView.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 17.12.25.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // MARK: - Info

            Text("Info")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                
                VStack(alignment: .leading) {
                    Text("Bright sunlight is recommended.")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Text(" Poor or uneven lighting can impact hand tracking and drum stick movement.")
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("System audio output is recommended.")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Text(" Bluetooth audio devices may introduce noticeable audio delay.")
                        .foregroundColor(.secondary)
                }
                
            }
            .font(.body)

            // MARK: - Credits

            Text("Credits")
                .font(.title)
                .fontWeight(.bold)

            Text("Developed by Oliver Hans Kühle, Philipp Mayr, Julius Immanuel Greppmair\n\nFun Drum by local.yany (CC Attribution) https://sketchfab.com/3d-models/drum-kit-57f6bb6e93c14762b0da1be2a50f1f44")
                .foregroundColor(.secondary)
                .font(.body)

            Spacer()
        }
        .padding(40)
    }
}

#Preview {
    InfoView()
}
