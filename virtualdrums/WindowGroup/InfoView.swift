//
//  InfoView.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 17.12.25.
//

import SwiftUI

struct InfoView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 20) {

            // MARK: - Info
            
            Button("Open Projekttag view", action: {
                appState.isProjekttag = true;
            })

            VStack(alignment: .leading, spacing: 12) {
                
                VStack(alignment: .leading) {
                    Text("Bright sunlight is recommended.")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Text(" Poor or uneven lighting can impact hand tracking and drum stick movement.")
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("Widgets can break collision detection.")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Text(" visionOS widgets placed on your walls may interfere with hand tracking, even though they aren’t visible in immersive spaces. Please remove them while using the app.")
                        .foregroundColor(.secondary)
                }
                
            }
            .font(.body)

            // MARK: - Credits

            VStack(alignment: .leading, spacing: 12) {
                Text("Credits")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Developed by\nOliver Hans Kühle, Philipp Mayr, Julius Immanuel Greppmair")
                    .foregroundColor(.secondary)
                    .font(.body)
                
                Text("Natal Drum by local.yany (CC Attribution) https://skfb.ly/6ZpKO\nOpal Drum by Glowbox 3D (CC Attribution) https://skfb.ly/oIXLv")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
        }
        .fixedSize(horizontal: false, vertical: true) // Allows text to wrap lines
        .padding(40)
    }
}

#Preview {
    InfoView()
}
