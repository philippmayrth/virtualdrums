## Architecture Overview

This app is a visionOS drum kit built with SwiftUI and RealityKit. The core flow is:

1. The user interacts with the immersive scene (hand tracking + spatial taps).
2. Stick motion is translated into raycasts and hit validation.
3. Hits trigger local audio playback and optional MIDI output.

The MIDI bridge is a separate Python service. See `midi_bridge/` for details.

## Main Components

### App Shell

- `virtualdrums/virtualdrumsApp.swift` sets up the windowed UI and immersive space.
- `virtualdrums/WindowGroup/ContentTabView.swift` holds the tab UI.
- `virtualdrums/AppState.swift` stores shared UI state and binds it to audio and MIDI.

### Immersive Scene Orchestration

- `virtualdrums/ImmersiveView.swift` hosts the `RealityView`.
- `virtualdrums/ImmersiveViewModel.swift` wires everything together:
  - Scene setup
  - Input handling
  - ARKit tracking
  - Drum hit routing
  - Simulator-only helpers

### Scene Setup

- `virtualdrums/DrumSetup.swift` loads the USDZ drum set, creates collision targets, and wires hi-hat/kick parts.
- `virtualdrums/StickSetup.swift` creates and anchors drum sticks to the hands.

### Input Processing

- `virtualdrums/ImmersiveViewModel.swift` converts hand tracking into stick motion and raycasts to validate hits.
- `virtualdrums/Singleton Managers/FootPedalManager.swift` maps game controller inputs to pedals.
- `virtualdrums/Singleton Managers/HandGripManager.swift` debounces grip state for reliable hits.

### Audio and MIDI

- `virtualdrums/Singleton Managers/AudioEngine.swift` loads samples and plays sounds.
- `virtualdrums/Singleton Managers/DrumController.swift` maps hits to audio and MIDI.
- `virtualdrums/Singleton Managers/MIDIBridgeClient.swift` sends HTTP events to the MIDI bridge.

## Data Flow (Hit Pipeline)

1. Stick tip moves each frame.
2. `StrikeProcessor` raycasts against drum colliders.
3. Valid hits call `ImmersiveViewModel.onDrumHit`.
4. `DrumController` plays sound and optionally sends MIDI.

## Assets and IDs

- Drum models: `virtualdrums/assets/drum sets/`
- Sound kits: `virtualdrums/assets/soundkit/`
- IDs: `virtualdrums/Models/DrumID.swift`, `virtualdrums/Models/DrumSetID.swift`, `virtualdrums/Models/DrumKitID.swift`

Naming is important:
- Drum piece meshes are named `target_<drum_piece>` inside USDZ.
- Sound files are named `<soundkit>_target_<drum_piece>`.

## Configuration

App-level constants live in `virtualdrums/Helpers/AppConfig.swift`.

## MIDI Bridge

The bridge is external to the app and runs as an HTTP server configured by the user.
See the docs in `midi_bridge/` for setup and mappings.
