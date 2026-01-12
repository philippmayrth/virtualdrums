# 🎹 VR Drumkit MIDI Bridge - Getting Started

A complete step-by-step guide to get your VR drums sending MIDI to Logic Pro.

## Prerequisites

- macOS 11.0 or later
- Python 3.11+ (`python3 --version`)
- Xcode 15+ (for building VR app)
- Logic Pro (or any DAW with virtual MIDI support)
- Vision Pro or Simulator

## Step 1: Set Up Python Environment

```bash
# Navigate to the bridge directory
cd /Users/passion/Desktop/VirtualDrums/virtualdrums/midi_bridge

# Install pipenv if you don't have it
pip3 install pipenv

# Install dependencies
pipenv install

# Verify MIDI works
pipenv run python check_midi.py
```

You should see:
```
✅ python-rtmidi is installed
✅ Available MIDI APIs: ...
✅ Can create MIDI output
✅ Can create virtual MIDI port
🎉 Your MIDI setup is working correctly!
```

## Step 2: Start the Bridge

```bash
./start.sh
```

Expected output:
```
🎹 Starting VR Drumkit MIDI Bridge...
✅ Created virtual MIDI port: VRDrumkit Virtual Out
✅ Audio system initialized (32 channels)
✅ Bridge ready! Listening for VR events...
```

Leave this running in a terminal window.

## Step 3: Test the Bridge

Open a **new terminal** and run:

```bash
cd /Users/passion/Desktop/VirtualDrums/virtualdrums/midi_bridge
pipenv run python test_bridge.py
```

This will:
- Verify bridge is running
- Send test drum hits
- Test kit selection
- Report any issues

Or try the interactive demo:
```bash
./demo.sh
```

## Step 4: Configure Logic Pro

### 4.1 Create a Track

1. Open Logic Pro
2. Create new project (or open existing)
3. **Track → New Software Instrument Track** (⌘⌥S)

### 4.2 Set MIDI Input

1. Click the instrument slot (or press **I** for Inspector)
2. Click the current instrument name → **External MIDI**
3. Select **"VRDrumkit Virtual Out"**

> 💡 If you don't see the port, restart the bridge and reopen Logic

### 4.3 Load a Drum Instrument

Choose one of these:

**Built-in Options:**
- **Drum Kit Designer** - Realistic acoustic drums
- **Ultrabeat** - Electronic drums and sound design
- **Drum Machine Designer** - Hip-hop/electronic

**Third-Party (if you have them):**
- Superior Drummer 3
- BFD3
- Steven Slate Drums

### 4.4 Enable Recording

1. Click the **R** (record enable) button on the track
2. Enable input monitoring (click **I** button or turn on monitoring)
3. You should see the track meters respond when bridge receives hits

## Step 5: Set Up the VR App

### 5.1 Add Files to Xcode

See [XCODE_SETUP.md](../XCODE_SETUP.md) for detailed instructions.

Quick version:
1. Open `virtualdrums.xcodeproj` in Xcode
2. Drag these files from Finder into Xcode:
   - `MIDIBridgeClient.swift`
   - `WindowGroup/MIDIBridgeSettingsView.swift`
3. Build (⌘B) to verify no errors

### 5.2 Build and Run

1. Select your target device (Vision Pro or Simulator)
2. Run the app (⌘R)
3. Navigate to the **"MIDI Bridge"** tab
4. Tap **"Test Connection"**
5. Should show **"Connected ✓"**

### 5.3 Start Playing

1. Switch to the immersive space
2. Start drumming!
3. Watch Logic's MIDI activity (Window → Show MIDI Activity)
4. Notes should appear as you hit drums

## Step 6: Record Your Performance

### Simple Recording

1. In Logic, click the main **Record** button (or press **R**)
2. Play drums in VR
3. Press **Stop** (Space bar)
4. Your MIDI is now recorded!

### Loop Recording

1. Enable **Cycle Mode** (press **C**)
2. Set the cycle region (drag in the ruler)
3. Press **Record**
4. Each loop creates a new take
5. Choose best take or create a comp

## Common Issues

### "Connection Failed" in VR App

**Cause:** Bridge not running or wrong URL

**Fix:**
```bash
# Verify bridge is running
curl http://localhost:5729/health

# If Vision Pro is on different network, use Mac's IP
# In VR app, change URL to: http://192.168.1.XXX:5729
```

### "No Virtual MIDI Port" in Logic

**Cause:** Port not created or Logic opened before bridge started

**Fix:**
1. Quit Logic Pro completely
2. Stop bridge (Ctrl+C)
3. Start bridge again: `./start.sh`
4. Verify port created: Open **Audio MIDI Setup** (Applications → Utilities)
5. Reopen Logic Pro
6. Port should now appear

### "Port Already in Use"

**Cause:** Another bridge instance is running

**Fix:**
```bash
# Find and kill the process
lsof -i :5729
kill -9 <PID>

# Or just restart terminal and run ./start.sh again
```

### "Import Error: rtmidi"

**Cause:** Dependencies not installed

**Fix:**
```bash
cd midi_bridge
pipenv install
pipenv run python check_midi.py
```

### Notes Stick / Don't Stop

**Cause:** Note Off messages not being sent properly

**Fix:**
- Check `noteOffDelay` in event payloads (default 0.1s)
- In Logic, ensure track is not in Latch mode
- Try closing and reopening Logic

### High Latency

**Causes:** Network delay, buffer settings, CPU load

**Fixes:**
- Use Ethernet instead of WiFi
- Reduce Logic buffer: **Preferences → Audio → I/O Buffer Size** → 128 or 256
- Close unnecessary apps
- Consider WebSocket upgrade (future)

## Next Steps

### Customize MIDI Mapping

Edit `midi_bridge/app.py`:
```python
DRUM_MIDI_MAP = {
    "target_snare": 40,  # Use rim shot
    "target_kick": 36,   # Standard kick
    # ... etc
}
```

### Add Local Audio Playback

Uncomment in `app.py`:
```python
soundkit_path = Path(__file__).parent.parent / "virtualdrums/assets/soundkit/accoustic"
bridge.setup_audio(soundkit_path)
```

### Automate Kit Changes in Logic

1. Record a track with drums
2. Use **Automation → Show Automation**
3. Select **External MIDI** → **CC #20** (drumkit)
4. Draw automation to change kits during playback

### Connect to Lighting

Extend `MIDIBridge.handle_drum_hit()` to fan out events:
```python
async def handle_drum_hit(self, drum_id: str, velocity: float):
    # ... MIDI code ...
    
    # Send to lighting rig
    await send_osc_message("/drums/hit", drum_id, velocity)
```

## File Structure

```
virtualdrums/
├── midi_bridge/           # Python MIDI bridge
│   ├── app.py            # Main server
│   ├── start.sh          # Startup script
│   ├── demo.sh           # Demo script
│   ├── test_bridge.py    # Test suite
│   ├── check_midi.py     # MIDI verification
│   ├── Pipfile           # Dependencies
│   └── README.md         # API docs
│
├── virtualdrums/         # VR app
│   ├── MIDIBridgeClient.swift
│   ├── DrumController.swift (modified)
│   ├── AppState.swift (modified)
│   └── WindowGroup/
│       ├── MIDIBridgeSettingsView.swift
│       └── ContentTabView.swift (modified)
│
├── MIDI_SETUP.md         # Complete documentation
├── XCODE_SETUP.md        # Xcode integration
└── GETTING_STARTED.md    # This file
```

## Learning Resources

### MIDI Basics
- [MIDI Association - MIDI 1.0 Specification](https://www.midi.org/specifications)
- GM (General MIDI) Drum Map - Channel 10 standard

### Logic Pro MIDI
- Logic Pro User Guide → Working with MIDI
- Virtual MIDI setup in Audio MIDI Setup
- Using External MIDI sources

### Python MIDI
- [python-rtmidi documentation](https://spotlightkid.github.io/python-rtmidi/)
- [Quart documentation](https://quart.palletsprojects.com/)

## Support

1. Check this guide thoroughly
2. Run `test_bridge.py` for diagnostics
3. Check console logs in both bridge and VR app
4. Verify MIDI activity in Logic's MIDI monitor
5. Review [MIDI_SETUP.md](../MIDI_SETUP.md) for advanced topics

---

**Ready to drum! 🥁 → 🎹 → 🎵**

Start the bridge, open Logic, launch the VR app, and start jamming!
