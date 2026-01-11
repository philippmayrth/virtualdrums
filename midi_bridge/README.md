# VR Drumkit MIDI Bridge

A lightweight Python helper that receives HTTP events from the VR drumkit app and converts them to MIDI output for Logic Pro and other DAWs.

## Features

- 🎹 **Virtual MIDI Port**: Creates "VRDrumkit Virtual Out" visible to Logic Pro
- 🥁 **Drum Events**: Converts HTTP POST requests to MIDI Note On/Off messages
- 🎨 **Kit Selection**: Handles drumkit (visual model) and soundkit (audio) changes
- 🎵 **MIDI Mapping**: Sends Program Change and CC messages for kit selection
- 🔊 **Optional Audio**: Can play local samples for demo/monitoring (polyphonic)

## Installation

1. Install pipenv if you don't have it:
   ```bash
   pip install pipenv
   ```

2. Install dependencies:
   ```bash
   cd midi_bridge
   pipenv install
   ```

## Usage

Start the bridge:
```bash
pipenv run python app.py
```

The server will:
- Create virtual MIDI port "VRDrumkit Virtual Out"
- Listen on `http://0.0.0.0:5729`
- Accept drum events at `/event`
- Accept selection changes at `/select`

## API Endpoints

### Health Check
```bash
GET /health
```

Response:
```json
{
  "status": "ok",
  "midi_port": "VRDrumkit Virtual Out",
  "audio_enabled": true,
  "current_drumkit": "accoustic",
  "current_soundkit": "drum_kit"
}
```

### Drum Hit Event
```bash
POST /event
Content-Type: application/json

{
  "drum": "target_snare",
  "velocity": 0.85,
  "noteOffDelay": 0.1
}
```

- `drum`: Drum ID (e.g., "target_snare", "target_bass_drum")
- `velocity`: Hit velocity (0.0 to 1.0)
- `noteOffDelay`: Optional, duration before Note Off (default: 0.1s)

### Kit Selection
```bash
POST /select
Content-Type: application/json

{
  "drumkit": "electronic",
  "soundkit": "burgundy_drum"
}
```

- `drumkit`: Visual drum model ("accoustic", "electronic", "alternative")
  - Sends MIDI CC #20 with value 0/1/2
- `soundkit`: Audio sample set ("drum_kit", "burgundy_drum")
  - Sends MIDI Program Change 0/1

## MIDI Mapping

### Drum Notes (Channel 10)

| Drum | MIDI Note | GM Standard |
|------|-----------|-------------|
| Bass Drum | 36 | Kick |
| Snare | 38 | Snare |
| Floor Tom | 41 | Floor Tom |
| Mid Tom | 47 | Mid Tom |
| High Tom | 50 | High Tom |
| Closed Hi-Hat | 42 | Closed HH |
| Open Hi-Hat | 46 | Open HH |
| Pedal Hi-Hat | 44 | Pedal HH |
| Ride | 51 | Ride |
| Crash | 49 | Crash |

### Kit Selection

- **DrumKit** (visual): CC #20
  - 0 = accoustic
  - 1 = electronic
  - 2 = alternative

- **SoundKit** (audio): Program Change
  - 0 = drum_kit
  - 1 = burgundy_drum

## Logic Pro Setup

1. Start the bridge (`pipenv run python app.py`)
2. Open Logic Pro
3. Create a Software Instrument track
4. Click the instrument slot → External MIDI → Select "VRDrumkit Virtual Out"
5. Load your favorite drum plugin (Ultrabeat, Superior Drummer, etc.)
6. Hit Record and play in VR!

## Testing

Test from terminal:
```bash
# Test drum hit
curl -X POST http://localhost:5729/event \
  -H "Content-Type: application/json" \
  -d '{"drum": "target_snare", "velocity": 0.9}'

# Test kit selection
curl -X POST http://localhost:5729/select \
  -H "Content-Type: application/json" \
  -d '{"drumkit": "electronic", "soundkit": "burgundy_drum"}'

# Check health
curl http://localhost:5729/health
```

## Optional: Local Audio Playback

To enable local audio monitoring, uncomment and configure the soundkit path in `app.py`:

```python
@app.before_serving
async def startup():
    # ...
    soundkit_path = Path(__file__).parent.parent / "virtualdrums/assets/soundkit/accoustic"
    bridge.setup_audio(soundkit_path)
```

This will play samples locally (with polyphony) in addition to sending MIDI.

## Architecture

```
VR App (Vision Pro)
    ↓ HTTP POST
MIDI Bridge (Mac)
    ├→ Virtual MIDI Out → Logic Pro
    └→ Optional: pygame audio (monitoring)
```

## Future Extensions

- Add WebSocket support for lower latency
- Support multiple VR clients
- Add OSC output for lighting systems
- Implement MIDI learn for custom mappings
- Add recording/playback of performances
