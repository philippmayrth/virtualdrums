# Virtual Drums

A virtual drum kit for Apple Vision Pro.

<img src="https://gitlab.informatik.hs-augsburg.de/pmx/virtualdrums/-/raw/b6374637913e36a5371a3e5460304f51f40543f4/virtualdrums/assets/Icons/Version2/full_transparent.png" width="300" height="300">

In the Virtual Drums project, we explore how future-ready VR technology really is. The app targets Apple Vision Pro and is built in Swift. The best way to evaluate new tech is hands-on—so we built a virtual drum kit. Inspired by the classic instrument, it lets you make music on Vision Pro while highlighting the boundaries of visionOS 26.

## 🥁 Documentation

- [DEVELOPERS.md](./DEVELOPERS.md) → Setup & onboarding
- [ARCHITECTURE.md](./ARCHITECTURE.md) → Components, flows, key classes
- [TNBT-Limitations.md](./TNBT-Limitations.md) → Documentation of the identified limitations of visionOS/VisionPro
- [/midi_bridge/...](./midi_bridge/) → Documentation on the MIDI bridge integration

## 🥁 Highlights

- Realistic, dynamic hit animations
- Hit strength controls volume and tone
- Multiple drum sets and sound kits
- Left/right-handed mode (mirroring)
- GameController support
- Optional MIDI output via bridge for DAWs

## 🥁 App Versions / Git Tags

- **1.7**: New icon, Adjustment-View
- **1.6**: *Version increased to resolve a submitted erroneous build*
- **1.5**: MIDI Bridge, New Sounds, Refactoring, Usability improvements, Handedness Support
- **1.4**: Tap gesture alternative for hi-hat pedal, Hand Grip Detection, Hi-Hat Cymbal & Kick Pedal move dynamically with controller trigger
- **1.3**: GameController input for foot pedals
- **1.2**: Keyboard input for foot pedals
- **1.1**: Improved Version using Raycast Collision Detection
- **1.0**: Working Version using CollisionEvents

## 🥁 External Software

- **Blender** (3D modeling software, free) https://www.blender.org/
- **Affinity (Designer)** (Design tool, freemium) https://www.affinity.studio