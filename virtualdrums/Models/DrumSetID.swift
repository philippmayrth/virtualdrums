
/// Identifies a 3D drum set layout in the scene.
///
/// A DrumSet represents the physical arrangement and visual appearance of the drums (models, positions, materials, and scale).
/// Changing the DrumSet changes how the kit looks in the world, but not which sounds are played.
enum DrumSetID: String, CaseIterable, Identifiable {
    case drum_kit
    case burgundy_drum

    var id: String { rawValue }
}
