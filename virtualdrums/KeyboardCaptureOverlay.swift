import SwiftUI

struct KeyboardCaptureOverlay: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var keyPressFocused: Bool
    @FocusState private var textFieldFocused: Bool
    @State private var textBuffer: String = ""

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

            TextField("", text: $textBuffer)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($textFieldFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: textBuffer) { oldValue, newValue in
                    handleTextInputChange(oldValue: oldValue, newValue: newValue)
                }
        }
        .onAppear {
            applyFocus(for: appState.keyboardInputMode)
        }
        .onChange(of: appState.keyboardInputMode) { _, newMode in
            applyFocus(for: newMode)
        }
    }

    private func applyFocus(for mode: KeyboardInputMode) {
        switch mode {
        case .hardware:
            keyPressFocused = true
            textFieldFocused = false
        case .textField:
            keyPressFocused = false
            textFieldFocused = true
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

    private func handleTextInputChange(oldValue: String, newValue: String) {
        if newValue.isEmpty {
            return
        }

        if newValue.count < oldValue.count {            
            return
        }

        let deltaCount = newValue.count - oldValue.count
        if deltaCount > 0 {
            let suffix = newValue.suffix(deltaCount)            
            let spaceCount = suffix.filter { $0 == " " }.count
            if spaceCount > 0 {
                appState.keyboardKickTriggerToken += spaceCount
            }
            let hiHatCount = suffix.filter { $0 == "h" || $0 == "H" }.count
            if hiHatCount > 0 {
                appState.keyboardHiHatTriggerToken += hiHatCount
            }
            let pedalCount = suffix.filter { $0 == "f" || $0 == "F" }.count
            if pedalCount > 0 {
                for _ in 0..<pedalCount {
                    appState.hiHatPedalIsClosed.toggle()
                }
            }
        }

        textBuffer = ""
    }
}
