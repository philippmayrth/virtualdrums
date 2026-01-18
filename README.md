# Virtual Drums

A virtual drum kit for Apple Vision Pro.

<img src="virtualdrums/Assets/Icons/Version2/full_transparent.png" width="300" height="300">

Im Projekt Virtual Drums haben wir uns die Frage gestellt, wie zukunftstauglich VR-Technologie tatsächlich ist. Als Plattform nutzen wir die Apple Vision Pro, programmiert mit Swift. Am besten lässt sich Technik evaluieren, indem man sie praktisch ausprobiert – daher haben wir ein virtuelles Drum Kit entwickelt. Inspiriert vom klassischen Instrument soll es die Möglichkeit bieten, mit der Apple Vision Pro Musik zu machen und dabei die Grenzen der Vision Pro und von visionOS 26 aufzeigen.

---

## 🥁 Highlights

- Realistische, dynamische Schlag-Animationen
- Anschlagstärke steuert Lautstärke und Klang
- Mehrere Drum Sets und Sound Kits
- Links-/Rechtshänder-Modus (Spiegelung)
- Optional: MIDI-Ausgabe via Bridge für DAWs

---

## 🥁 App Versions (Git Tags)

- **1.7**: New icon, Adjustment-View
- **1.6**: *Version increased to resolve a submitted erroneous build*
- **1.5**: MIDI Bridge, New Sounds, Refactoring, Usability improvements, Handedness Support
- **1.4**: Tap gesture alternative for hi-hat pedal, Hand Grip Detection, Hi-Hat Cymbal & Kick Pedal move dynamically with controller trigger
- **1.3**: GameController input for foot pedals
- **1.2**: Keyboard input for foot pedals
- **1.1**: Improved Version using Raycast Collision Detection
- **1.0**: Working Version using CollisionEvents

---

## 🥁 External Software

- **Blender** (3D modeling software, free) https://www.blender.org/
- **Affinity (Designer)** (Design tool, freemium) https://www.affinity.studio

---

## 🥁 3D Drum Models

Located in `virtualdrums/assets/drum sets`.

- A **drum set model** is provided as a `.usdz` file and can be imported as an `Entity`.
- Each `.usdz` file may contain multiple drum pieces, **each with its own separate mesh**.
- Each drum piece that should trigger collisions with the stick must have its **mesh** be named : `target_[drum-piece-name]` (e.g. `target_hi_hat_top`).
- When imported, every drum piece becomes a `ModelEntity`, which is then a child of the root `Entity`.

The available drum sets are defined in `DrumSetID.swift`.
Their modular drum pieces are defined in `DrumID.swift`.

### Editing `.usdz` in Blender

1. Import the `.usdz` file into Blender
2. Edit as needed
3. Click "Export as **Universal Scene Description (.usd*)**"
4. Rename the exported file from `.usdc` to `.usdz` before exporting
5. Export (easily check correctness using the Preview app)

**Important: Axis Orientation**

We compare the raycast hit normal (strike direction) with the UP vector of the drum piece.
Therefore the drum face (piece that should be hit) must point up and the rotation must be preserved and to applied to or baked into the mesh.

---

## 🥁 Sounds

Located in `virtualdrums/assets/soundkit`.

- Files must be named: `[soundkit-name]_target_[drum-piece-name]` (e.g. `accoustic_target_hi_hat`)
- Every soundkit must have a sound for each drum piece (see `DrumID.swift`).

The available sounds kits are defined in `DrumKitID.swift`.

---

## 🥁 App Icon

Located in `virtualdrums/assets/icon`

### /Version 1

There are two types. Prefixed with `App` are used inside of Xcode and prefixed with `Marketing` can be used on App Store Connect. There are @1 and @2 available for most.

### /Version 2

Contains the three components – *front, middle and back* – for creating the Icon in Xcode, as well a version – *full_transparent* – containing all layers, to be used on social media etc.

---

## 🎹 NEW: MIDI Bridge Integration

**Record your VR drum performances in Logic Pro!**

We've added a complete MIDI bridge system that lets you send drum events from the VR app to Logic Pro (or any DAW) for professional recording and production.

### Quick Start

```bash
# 1. Start the Python MIDI bridge
cd midi_bridge
./start.sh

# 2. Open Logic Pro and configure MIDI input
# 3. Build and run the VR app
# 4. Start drumming - Logic records MIDI!
```

### Documentation

All MIDI bridge documentation is located in the [midi_bridge/](midi_bridge/) folder:

- **[GETTING_STARTED.md](midi_bridge/GETTING_STARTED.md)** - Step-by-step setup (start here!)
- **[QUICK_REFERENCE.md](midi_bridge/QUICK_REFERENCE.md)** - One-page cheat sheet
- **[MIDI_SETUP.md](midi_bridge/MIDI_SETUP.md)** - Complete documentation
- **[ARCHITECTURE_DIAGRAMS.md](midi_bridge/ARCHITECTURE_DIAGRAMS.md)** - System architecture
- **[PROJECT_COMPLETION.md](midi_bridge/PROJECT_COMPLETION.md)** - Implementation summary

### Features

- 🥁 HTTP → MIDI translation (all drum events)
- 🎹 Virtual MIDI port ("VRDrumkit Virtual Out")
- 🎨 Kit selection with MIDI CC/Program Change
- 🔊 Optional local audio playback
- ⚙️ Settings UI in VR app
- 📡 Works over WiFi or Ethernet
- 🎵 Ready for Logic Pro, Ableton, etc.

### Architecture

```
VR App (Vision Pro) → HTTP → Python Bridge → MIDI → Logic Pro
```

See [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md) for detailed diagrams.