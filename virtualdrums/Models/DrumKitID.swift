
/// Identifies a sound kit used by the audio engine.
///
/// Changing the DrumKit affects how the drums sound, but does not affect the 3D models or layout.
enum DrumKitID: String, CaseIterable, Identifiable {
    case accoustic
    case electronic
    case alternative

    var id: String { rawValue }
}
