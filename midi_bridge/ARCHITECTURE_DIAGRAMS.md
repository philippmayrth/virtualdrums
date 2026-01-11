# System Architecture Diagrams

## High-Level Overview

```
┌─────────────────────────────────────────────────────┐
│                  Vision Pro                          │
│                                                       │
│   ┌─────────────────────────────────────────────┐  │
│   │         VR Drumkit Application              │  │
│   │                                              │  │
│   │  • Hand tracking                            │  │
│   │  • Collision detection                      │  │
│   │  • Velocity calculation                     │  │
│   │  • Visual/audio feedback                    │  │
│   └──────────────────┬──────────────────────────┘  │
│                      │                               │
└──────────────────────┼───────────────────────────────┘
                       │
                       │ WiFi/Ethernet
                       │ HTTP POST: JSON
                       │ {"drum": "...", "velocity": 0.8}
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│                      Mac                             │
│                                                       │
│   ┌──────────────────────────────────────────────┐ │
│   │      Python MIDI Bridge (Quart)              │ │
│   │      Port: 5729                              │ │
│   │                                               │ │
│   │  • Receives HTTP events                      │ │
│   │  • Translates to MIDI                        │ │
│   │  • Creates virtual port                      │ │
│   │  • Optional: plays samples                   │ │
│   └──────────────────┬───────────────────────────┘ │
│                      │                               │
│                      │ MIDI Messages                 │
│                      │ (IAC Driver / Virtual Port)   │
│                      ▼                               │
│   ┌──────────────────────────────────────────────┐ │
│   │           Logic Pro                          │ │
│   │                                               │ │
│   │  • Receives MIDI from virtual port           │ │
│   │  • Routes to drum plugin                     │ │
│   │  • Records MIDI data                         │ │
│   │  • Processes audio                           │ │
│   └──────────────────┬───────────────────────────┘ │
│                      │                               │
│                      ▼                               │
│              ┌──────────────┐                       │
│              │ Audio Output │                       │
│              └──────────────┘                       │
└─────────────────────────────────────────────────────┘
```

## Detailed Data Flow

### Drum Hit Event Flow

```
┌────────────────────────────────────────────────────────────┐
│ 1. USER HITS DRUM IN VR                                    │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│ 2. VR APP - Collision Detection                            │
│    ImmersiveView detects hand/stick collision              │
│    Calculates strike speed from velocity                   │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│ 3. DrumController.hitDrum(drum, strikeSpeed)               │
│    • Determines which sound (open/closed hi-hat)           │
│    • Calculates volume from speed                          │
│    • Normalizes velocity (0-1)                             │
└────────────┬───────────────────────────────────────────────┘
             │
             ├─────────────────────────────────────────┐
             │                                         │
             ▼                                         ▼
┌─────────────────────────────┐    ┌─────────────────────────────┐
│ AudioEngine.playSound()     │    │ MIDIBridgeClient.sendHit()  │
│ • Plays local sample        │    │ • Creates JSON payload      │
│ • With velocity             │    │ • HTTP POST to bridge       │
└─────────────────────────────┘    └────────────┬────────────────┘
                                                 │
                                                 │ Network
                                                 │
                                                 ▼
┌────────────────────────────────────────────────────────────┐
│ 4. PYTHON BRIDGE - /event endpoint                         │
│    • Parses JSON: {drum, velocity, noteOffDelay}           │
│    • Validates input                                       │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│ 5. MIDIBridge.handle_drum_hit()                            │
│    • Maps drum ID → MIDI note (e.g., snare → 38)          │
│    • Converts velocity (0-1) → MIDI velocity (0-127)      │
│    • Sends MIDI Note On [0x99, note, velocity]            │
│    • Schedules Note Off after delay                        │
│    • Optional: plays local audio sample                    │
└────────────┬───────────────────────────────────────────────┘
             │
             │ CoreMIDI / python-rtmidi
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│ 6. VIRTUAL MIDI PORT: "VRDrumkit Virtual Out"             │
│    • Broadcasts MIDI message to all listeners              │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│ 7. LOGIC PRO - MIDI Input                                  │
│    • Receives on Channel 10                                │
│    • Routes to selected drum plugin                        │
│    • If recording: adds to MIDI region                     │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│ 8. DRUM PLUGIN (Ultrabeat, etc)                            │
│    • Triggers sample for MIDI note 38                      │
│    • Applies velocity to volume                            │
│    • Processes through plugin effects                      │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│ 9. AUDIO ENGINE                                            │
│    • Mixes with other tracks                               │
│    • Applies master effects                                │
│    • Outputs to speakers/headphones                        │
└────────────────────────────────────────────────────────────┘
             │
             ▼
        🔊 SOUND!
```

### Kit Selection Event Flow

```
┌────────────────────────────────────────────────────────────┐
│ 1. USER SELECTS NEW KIT IN VR APP                         │
│    (e.g., changes from "acoustic" to "electronic")        │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│ 2. AppState.$selectedDrumKit published value changes       │
│    • SwiftUI Combine publisher fires                       │
│    • All subscribers notified                              │
└────────────┬───────────────────────────────────────────────┘
             │
             ├─────────────────────────────────────────┐
             │                                         │
             ▼                                         ▼
┌─────────────────────────────┐    ┌─────────────────────────────┐
│ AudioEngine.setDrumKit()    │    │ MIDIBridgeClient.sendKit()  │
│ • Loads new sample set      │    │ • Creates JSON payload      │
│ • Unloads old samples       │    │ • HTTP POST to /select      │
└─────────────────────────────┘    └────────────┬────────────────┘
                                                 │
                                                 ▼
┌────────────────────────────────────────────────────────────┐
│ 3. PYTHON BRIDGE - /select endpoint                        │
│    • Parses: {drumkit: "electronic", soundkit: "..."}     │
└────────────┬───────────────────────────────────────────────┘
             │
             ├───────────────────────────┬─────────────────────┐
             │                           │                     │
             ▼                           ▼                     ▼
┌──────────────────────┐  ┌──────────────────────┐  ┌────────────────┐
│ select_drumkit()     │  │ select_soundkit()    │  │ Update state   │
│ • Map to CC value    │  │ • Map to program #   │  │ • Store current│
│ • Send CC #20        │  │ • Send Prog Change   │  │   selection    │
│ • Value 0/1/2        │  │ • Value 0/1          │  └────────────────┘
└──────────┬───────────┘  └──────────┬───────────┘
           │                         │
           │ MIDI CC                 │ MIDI Program Change
           │ [0xB9, 20, value]       │ [0xC9, program]
           │                         │
           └──────────┬──────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────────┐
│ 4. LOGIC PRO receives control messages                     │
│    • Can automate these as track automation                │
│    • Can trigger smart controls                            │
│    • Can route to plugin parameters                        │
└────────────────────────────────────────────────────────────┘
```

## Component Architecture

### Python Bridge Components

```
app.py
├── Quart Application
│   ├── @app.route('/health')
│   ├── @app.route('/event')
│   └── @app.route('/select')
│
├── MIDIBridge Class
│   ├── setup_midi()
│   │   └── Creates virtual port via rtmidi
│   │
│   ├── setup_audio()
│   │   └── Initializes pygame mixer
│   │
│   ├── handle_drum_hit()
│   │   ├── Map drum ID → MIDI note
│   │   ├── Send Note On
│   │   ├── Schedule Note Off
│   │   └── Optional: play local audio
│   │
│   ├── select_drumkit()
│   │   └── Send CC #20
│   │
│   └── select_soundkit()
│       └── Send Program Change
│
└── Global State
    ├── DRUM_MIDI_MAP: dict[str, int]
    ├── DRUMKIT_CC_MAP: dict[str, int]
    └── SOUNDKIT_PROGRAM_MAP: dict[str, int]
```

### Swift VR App Components

```
VR App
├── MIDIBridgeClient (Singleton)
│   ├── baseURL: String
│   ├── isEnabled: Bool
│   ├── sendDrumHit(drum, velocity)
│   ├── sendKitSelection(drumKit?, soundKit?)
│   └── checkHealth() async
│
├── DrumController
│   ├── hitDrum(drum, strikeSpeed)
│   │   ├── Calculate volume
│   │   ├── Play local audio
│   │   └── Send to bridge ← NEW
│   │
│   └── Foot pedal bindings
│
├── AppState (@Observable)
│   ├── @Published selectedDrumKit
│   │   └── onChange → send to bridge ← NEW
│   │
│   ├── @Published selectedDrumSet
│   │   └── onChange → send to bridge ← NEW
│   │
│   └── isImmersiveSpaceOpen
│
└── MIDIBridgeSettingsView
    ├── URL configuration
    ├── Enable/disable toggle
    ├── Connection test button
    └── Status indicator
```

## Network Protocol

### Request Examples

```
# Drum hit
POST http://localhost:5729/event
Content-Type: application/json

{
  "drum": "target_snare",
  "velocity": 0.85,
  "noteOffDelay": 0.1
}

Response: {"status": "ok", "drum": "target_snare", "velocity": 0.85}
```

```
# Kit selection
POST http://localhost:5729/select
Content-Type: application/json

{
  "drumkit": "electronic",
  "soundkit": "burgundy_drum"
}

Response: {
  "status": "ok",
  "current_drumkit": "electronic",
  "current_soundkit": "burgundy_drum"
}
```

```
# Health check
GET http://localhost:5729/health

Response: {
  "status": "ok",
  "midi_port": "VRDrumkit Virtual Out",
  "audio_enabled": true,
  "current_drumkit": "accoustic",
  "current_soundkit": "drum_kit"
}
```

## MIDI Message Format

### Note On (Drum Hit)
```
Byte 1: 0x99 (Note On, Channel 10)
        │
        ├─ 0x90 = Note On command
        └─ 0x09 = Channel 10 (drums)

Byte 2: 0x26 (Note number, e.g., 38 for snare)
Byte 3: 0x58 (Velocity, 0-127)

Example: [0x99, 0x26, 0x58]
         = Note On, Channel 10, Note 38 (Snare), Velocity 88
```

### Note Off
```
Byte 1: 0x89 (Note Off, Channel 10)
Byte 2: 0x26 (Note number)
Byte 3: 0x00 (Velocity 0)

Example: [0x89, 0x26, 0x00]
         = Note Off, Channel 10, Note 38
```

### Control Change (Drumkit Selection)
```
Byte 1: 0xB9 (Control Change, Channel 10)
Byte 2: 0x14 (CC #20)
Byte 3: 0x01 (Value 0-2: acoustic/electronic/alternative)

Example: [0xB9, 0x14, 0x01]
         = CC #20, Channel 10, Value 1 (electronic)
```

### Program Change (Soundkit Selection)
```
Byte 1: 0xC9 (Program Change, Channel 10)
Byte 2: 0x01 (Program number 0-1)

Example: [0xC9, 0x01]
         = Program 1, Channel 10 (burgundy_drum)
```

## State Machine

### Bridge State
```
┌─────────────┐
│   STOPPED   │
└──────┬──────┘
       │ ./start.sh
       ▼
┌─────────────┐
│ INITIALIZING│
│ • Load deps │
│ • Open port │
└──────┬──────┘
       │ Success
       ▼
┌─────────────┐     HTTP Request      ┌──────────────┐
│    READY    │◄─────────────────────▶│  PROCESSING  │
│ • Listening │   Process & Respond   │  • Parse JSON│
│ • Idle      │                       │  • Send MIDI │
└──────┬──────┘                       └──────────────┘
       │ Ctrl+C
       ▼
┌─────────────┐
│  SHUTDOWN   │
│ • Close port│
│ • Cleanup   │
└─────────────┘
```

### VR App State
```
┌──────────────┐
│  LAUNCHED    │
└──────┬───────┘
       │
       ▼
┌──────────────┐    User enters     ┌─────────────────┐
│   WINDOW     │───────────────────▶│  IMMERSIVE      │
│   GROUP      │                    │   SPACE         │
│              │◄───────────────────│                 │
│ • Settings   │    User exits      │ • Drum playing  │
│ • Selection  │                    │ • Hit detection │
└──────────────┘                    └────────┬────────┘
       │                                     │
       │ Bridge enabled                      │ Drum hit
       │                                     │
       ▼                                     ▼
┌──────────────┐                    ┌─────────────────┐
│   BRIDGE     │                    │  SEND TO BRIDGE │
│  CONNECTED   │                    │  • JSON payload │
└──────────────┘                    │  • Async POST   │
                                    └─────────────────┘
```

## Timing Diagram

```
Time →

VR App:     |──Hit──|         |──────────────────|
            ↓       ↓         ↓                  ↓
            Detect  Local     HTTP POST          Next hit
                    Audio

Network:              |─5-20ms─|
                      Transfer

Bridge:                      |──Parse──|─Map─|──MIDI──|
                                  1ms     <1ms    1ms

Logic:                                          |──Plugin──|──Audio──|
                                                    5-10ms    5-20ms

Total:      0ms     5ms       25ms      26ms   27ms    35ms    55ms
            ↑       ↑         ↑         ↑      ↑       ↑       ↑
            Hit     VR        Bridge    MIDI   Logic   Process Output
            Detect  Audio     Receive   Send   Receive
```

## File Structure Map

```
virtualdrums/
│
├── midi_bridge/                    ← Python MIDI Bridge
│   ├── app.py                     ← Main server (START HERE)
│   ├── Pipfile                    ← Dependencies
│   ├── start.sh                   ← Quick start script
│   ├── test_bridge.py             ← Automated tests
│   ├── demo.sh                    ← Interactive demo
│   ├── check_midi.py              ← MIDI verification
│   ├── README.md                  ← API docs
│   └── .gitignore
│
├── virtualdrums/                   ← VR App
│   ├── MIDIBridgeClient.swift     ← NEW: HTTP client
│   ├── DrumController.swift       ← MODIFIED: sends events
│   ├── AppState.swift              ← MODIFIED: sends selection
│   ├── AudioEngine.swift
│   ├── FootPedalManager.swift
│   ├── HandGripManager.swift
│   ├── ImmersiveView.swift
│   ├── virtualdrumsApp.swift
│   ├── Info.plist                 ← MODIFIED: network perms
│   │
│   └── WindowGroup/
│       ├── MIDIBridgeSettingsView.swift  ← NEW: Settings UI
│       ├── ContentTabView.swift          ← MODIFIED: added tab
│       ├── DrumKitView.swift
│       ├── DrumSetView.swift
│       ├── FootPedalView.swift
│       └── InfoView.swift
│
├── GETTING_STARTED.md              ← START HERE for setup
├── QUICK_REFERENCE.md              ← Cheat sheet
├── MIDI_SETUP.md                   ← Complete documentation
├── IMPLEMENTATION_SUMMARY.md       ← Architecture details
├── XCODE_SETUP.md                  ← How to add files
├── PROJECT_COMPLETION.md           ← Overall summary
└── ARCHITECTURE_DIAGRAMS.md        ← This file
```

---

These diagrams provide a comprehensive visual understanding of the system architecture, data flow, and component interactions.
