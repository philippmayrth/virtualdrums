import Foundation

enum KeyboardInputMode: String, CaseIterable, Identifiable {
    case hardware
    case textField

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hardware:
            return "Hardware"
        case .textField:
            return "Textfeld"
        }
    }
}
