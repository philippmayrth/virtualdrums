# Developer Onboarding

This doc is for new contributors and reviewers. It focuses on the `virtualdrums/` app code.

## Quick Start

1. Open `virtualdrums.xcodeproj` in Xcode.
2. Select the `virtualdrums` target and a visionOS device or simulator.
3. Build and run.

If you want MIDI output to a DAW, see `midi_bridge/` for setup and usage.

## Prerequisites

- Xcode with visionOS support.
- Apple Vision Pro device or visionOS simulator.
- Optional: A game controller for foot pedals.
- Optional: Python environment for `midi_bridge/` (see its docs).

## Project Structure (High Level)

- `virtualdrums/` — main SwiftUI + RealityKit app.
- `virtualdrums/WindowGroup/` — UI tabs and settings views.
- `virtualdrums/Singleton Managers/` — audio, MIDI bridge client, foot pedals.
- `virtualdrums/Models/` — IDs and small model types.
- `virtualdrums/Helpers/` — app-wide configuration and small utilities.
- `virtualdrums/assets/` — USDZ drum sets, sound kits, icons, external source files.
- `midi_bridge/` — HTTP -> MIDI bridge with its own documentation.

## Key Entry Points

- App entry: `virtualdrums/virtualdrumsApp.swift`
- Main UI tabs: `virtualdrums/WindowGroup/ContentTabView.swift`
- Immersive scene: `virtualdrums/ImmersiveView.swift`
- Orchestration: `virtualdrums/ImmersiveViewModel.swift`

## Typical Developer Tasks

- Adjust drum kit or sound kit defaults: `virtualdrums/Helpers/AppConfig.swift`
- Add or tune hit behavior: `virtualdrums/ImmersiveViewModel.swift`, `virtualdrums/StrikeProcessor.swift`
- Add new drum model: `virtualdrums/assets/drum sets/` + update IDs in `virtualdrums/Models/DrumSetID.swift`
- Add new sounds: `virtualdrums/assets/soundkit/` + update IDs in `virtualdrums/Models/DrumKitID.swift`
- MIDI bridge integration: `virtualdrums/Singleton Managers/MIDIBridgeClient.swift`

## Editing `.usdz` in Blender

1. Import the `.usdz` file into Blender.
2. Edit as needed.
3. Export as **Universal Scene Description (.usd*)**.
4. Rename the exported file from `.usdc` to `.usdz`.
5. Export and verify (Preview app works well).

**Important: Axis Orientation**

We compare the raycast hit normal (strike direction) with the UP vector of the drum piece.
Therefore the drum face (piece that should be hit) must point up and the rotation must be preserved and applied or baked into the mesh.

## Simulator Notes

The simulator has debug helpers for stick movement and hit testing. See:

- `virtualdrums/DebugSimulator/ImmersiveView+Simulator.swift`
- `virtualdrums/DebugSimulator/SimulatorState.swift`
- `virtualdrums/DebugSimulator/SimulatorDebugViews.swift`

## App Icon Assets

Located in `virtualdrums/assets/icon`.

- **Version 1**: `App` files for Xcode, `Marketing` files for App Store Connect. Both @1 and @2 variants.
- **Version 2**: `front`, `middle`, and `back` layers for Xcode, plus `full_transparent` for social media.

## Review Tips

- Follow the hit pipeline: `ImmersiveView` -> `ImmersiveViewModel` -> `StrikeProcessor` -> `DrumController`.
- Check audio and MIDI routing in `virtualdrums/Singleton Managers/`.
- Asset naming conventions matter (drum pieces must be named with `target_...` and sound kits with `[soundkit]_target_...`).

## App Store

- For issues regarding the App Store contact Oliver Kühle at hello@oliverkuehle.de.
