# VR Drumkit → Logic Pro MIDI Integration

## Quick Start Guide

This proof-of-concept connects your VR drumkit app to Logic Pro through a Python MIDI bridge.

### Architecture

```
┌─────────────────┐
│   VR App        │  Vision Pro
│  (Swift/VR)     │  - Drum hits with velocity
└────────┬────────┘  - Kit selection
         │ HTTP POST (JSON)
         ↓
┌─────────────────┐
│  MIDI Bridge    │  Mac (Python/Quart)
│   (Python)      │  - Creates virtual MIDI port
│                 │  - Converts HTTP → MIDI
│                 │  - Optional local audio
└────────┬────────┘
         │ MIDI Messages
         ↓
┌─────────────────┐
│   Logic Pro     │  Mac
│   (DAW)         │  - Records MIDI
│                 │  - Drum plugins
│                 │  - Automation
└─────────────────┘
         │ Optional
         ↓
┌─────────────────┐
│  Lighting Rig   │  (Future)
│   (OSC/MIDI)    │  - DMX control
└─────────────────┘
```

## Installation

### 1. Install Python Dependencies

```bash
cd virtualdrums/midi_bridge
pip3 install pipenv
pipenv install
```

### 2. Start the MIDI Bridge

```bash
./start.sh
```

You should see:
```
✅ Created virtual MIDI port: VRDrumkit Virtual Out
✅ Audio system initialized (32 channels)
✅ Bridge ready! Listening for VR events...
```

### 3. Configure Logic Pro

1. Open Logic Pro
2. Create a new Software Instrument track
3. Click on the instrument slot → **External MIDI**
4. Select **"VRDrumkit Virtual Out"**
5. Load your favorite drum plugin:
   - **Ultrabeat** (built-in, great for electronic drums)
   - **Drum Kit Designer** (built-in, acoustic drums)
   - **Superior Drummer 3** (third-party, realistic)
   - **BFD3** (third-party, detailed)

### 4. Build & Run VR App

1. Open `virtualdrums.xcodeproj` in Xcode
2. Build and run on Vision Pro (or Simulator)
3. In the app, go to the **"MIDI Bridge"** tab
4. Test the connection (should show green ✓)
5. Switch to Immersive Space and start drumming!

### 5. Test the System

From terminal:
```bash
cd virtualdrums/midi_bridge
pipenv run python test_bridge.py
```

This will:
- Check bridge connectivity
- Send test drum hits
- Test kit selection
- Verify MIDI output

## Usage

### VR App Controls

- **Drums Tab**: Select visual drum model (drum_kit, burgundy_drum)
- **Sounds Tab**: Select audio soundkit (accoustic, electronic, alternative)
- **MIDI Bridge Tab**: Configure connection and test
- **Immersive Space**: Play drums with hand tracking or controllers

### MIDI Mapping

All drum events are sent on **MIDI Channel 10** (standard GM drums):

| Drum          | MIDI Note | GM Standard    |
|---------------|-----------|----------------|
| Bass Drum     | 36        | Kick           |
| Snare         | 38        | Snare          |
| Floor Tom     | 41        | Floor Tom      |
| Mid Tom       | 47        | Mid Tom        |
| High Tom      | 50        | High Tom       |
| Closed Hi-Hat | 42        | Closed HH      |
| Open Hi-Hat   | 46        | Open HH        |
| Pedal Hi-Hat  | 44        | Pedal HH       |
| Ride          | 51        | Ride Cymbal    |
| Crash         | 49        | Crash Cymbal   |

### Kit Selection

The bridge maintains two types of kit selection:

1. **DrumKit** (visual model in VR)
   - Sends MIDI CC #20
   - Values: 0=accoustic, 1=electronic, 2=alternative
   - Use this to switch visual appearance

2. **SoundKit** (audio sample set)
   - Sends MIDI Program Change
   - Values: 0=drum_kit, 1=burgundy_drum
   - Use this to switch sound library

Both can trigger automation in Logic Pro!

## Recording in Logic Pro

### Basic Recording
1. Enable recording on the drum track
2. Hit Record (R) in Logic
3. Play drums in VR
4. Stop recording

### Advanced: Record Multiple Takes
1. Enable Cycle Mode (C)
2. Set loop region over desired bars
3. Hit Record
4. Each loop creates a new take (Cycle Recording)
5. Choose best take or comp takes together

### Automation
You can automate kit changes:
- CC #20 changes drumkit (visual)
- Program Change switches soundkits
- Automate these in Logic for dynamic performances

## Customization

### Change Bridge Port/Host

In VR app → MIDI Bridge tab, change URL to your Mac's IP:
```
http://192.168.1.100:5729
```

Or edit `MIDIBridgeClient.swift`:
```swift
var baseURL = "http://YOUR_MAC_IP:5729"
```

### Add Local Audio Playback

Edit `midi_bridge/app.py`, uncomment in `startup()`:
```python
soundkit_path = Path(__file__).parent.parent / "virtualdrums/assets/soundkit/accoustic"
bridge.setup_audio(soundkit_path)
```

This plays samples locally (with polyphony) for monitoring.

### Custom MIDI Mapping

Edit `DRUM_MIDI_MAP` in `app.py`:
```python
DRUM_MIDI_MAP = {
    "target_snare": 40,  # Use rim shot instead
    # ... customize other drums
}
```

### Add Lighting Integration

Add to `MIDIBridge.handle_drum_hit()`:
```python
# Fan out to lighting system
await send_to_lighting(drum_id, velocity)
```

Implement OSC, DMX, or HTTP endpoints for your lighting rig.

## Troubleshooting

### "Connection Failed" in VR App

1. Check bridge is running: `curl http://localhost:5000/health`
2. If on different device, use Mac's IP address
3. Check firewall isn't blocking port 5000

### "No MIDI Port in Logic"

1. Quit Logic Pro
2. Restart bridge: `./start.sh`
3. Verify port exists: `ls /dev/midi*` or use Audio MIDI Setup
4. Reopen Logic Pro
5. The port should appear under External MIDI

### "No Sound in Logic"

1. Check MIDI Monitor (Window → Show MIDI Activity)
2. Verify notes are coming in (should flash on hits)
3. Check drum plugin is loaded
4. Verify track is record-enabled and monitoring
5. Check Logic's input level meters

### "Latency Issues"

1. Reduce Logic's I/O Buffer Size (Preferences → Audio)
2. Use ethernet instead of WiFi for Vision Pro
3. Consider WebSocket instead of HTTP (future improvement)
4. Disable local audio playback in bridge

### "Bridge Crashes on Startup"

Check MIDI backend:
```bash
pipenv run python -c "import rtmidi; print(rtmidi.get_compiled_api())"
```

If issues, reinstall with specific backend:
```bash
pipenv install python-rtmidi --upgrade
```

## Performance Tips

### For Best Latency
- Use Ethernet connection when possible
- Set Logic buffer size to 128 or 256 samples
- Disable unnecessary plugins/effects while recording
- Close other apps using audio/network

### For Best Results
- Calibrate hand tracking in Vision Pro settings
- Use good lighting in play area
- Practice dynamics (soft/loud hits)
- Record multiple takes and comp the best

## Future Enhancements

Potential improvements for this POC:

- [ ] WebSocket connection for lower latency
- [ ] OSC output for lighting control
- [ ] MIDI CC for per-drum parameters (pitch, decay, etc.)
- [ ] Recording mode (store performance, replay)
- [ ] Multi-client support (jam sessions)
- [ ] iOS/iPadOS companion app
- [ ] Ableton Link sync
- [ ] Custom drum mapping UI
- [ ] Audio visualization in VR
- [ ] Cloud recording/sharing

## API Reference

See [midi_bridge/README.md](midi_bridge/README.md) for complete API documentation.

## License

Same as main VirtualDrums project.

## Support

For issues or questions:
1. Check this documentation
2. Run test suite: `pipenv run python test_bridge.py`
3. Check bridge logs for errors
4. Verify Logic's MIDI monitor

---

**Have fun drumming! 🥁🎹**
