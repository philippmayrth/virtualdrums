import SwiftUI

struct KeyboardCaptureOverlay: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var keyPressFocused: Bool

    var body: some View {
        ZStack {
            Color.clear
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .focusable()
                .focused($keyPressFocused)
                .onKeyPress { press in                    
                    if press.phase.contains(.down) {
                        handleKeyDown(press.characters)
                    }
                    return .handled
                }
        }
        .onAppear {
            keyPressFocused = true
        }
    }

    private func handleKeyDown(_ characters: String) {
        if characters == " " {
            appState.keyboardKickTriggerToken += 1
            return
        }
        let lowered = characters.lowercased()
        if lowered == "h" {
            appState.keyboardHiHatTriggerToken += 1
        } else if lowered == "f" {
            appState.hiHatPedalIsClosed.toggle()
        }
    }
}