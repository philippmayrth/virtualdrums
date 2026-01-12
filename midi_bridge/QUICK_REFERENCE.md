# 🥁 VR Drumkit MIDI Bridge - Quick Reference

## Start Everything

```bash
# Terminal 1: Start bridge
cd ~/Desktop/VirtualDrums/virtualdrums/midi_bridge
./start.sh

# Terminal 2: Test (optional)
pipenv run python test_bridge.py

# Xcode: Build and run VR app
# Logic Pro: Open with drum track
```

## Common Commands

```bash
# Test connection
curl http://localhost:5729/health

# Send drum hit
curl -X POST http://localhost:5729/event \
  -H "Content-Type: application/json" \
  -d '{"drum": "target_snare", "velocity": 0.8}'

# Change kit
curl -X POST http://localhost:5729/select \
  -H "Content-Type: application/json" \
  -d '{"drumkit": "electronic"}'

# Run demo
./demo.sh
```

## MIDI Mapping Reference

| Drum | MIDI Note | CC Name |
|------|-----------|---------|
| Kick | 36 | C1 |
| Snare | 38 | D1 |
| Floor Tom | 41 | F1 |
| Mid Tom | 47 | B1 |
| High Tom | 50 | D2 |
| Closed HH | 42 | F#1 |
| Open HH | 46 | A#1 |
| Pedal HH | 44 | G#1 |
| Ride | 51 | D#2 |
| Crash | 49 | C#2 |

## Kit Selection

**DrumKit (visual):** CC #20
- 0 = accoustic
- 1 = electronic  
- 2 = alternative

**SoundKit (audio):** Program Change
- 0 = drum_kit
- 1 = burgundy_drum

## Troubleshooting Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| Connection failed | `curl http://localhost:5729/health` |
| No MIDI port | Restart bridge, reopen Logic |
| Port in use | `lsof -i :5729` then `kill -9 <PID>` |
| Import errors | `cd midi_bridge && pipenv install` |
| No sound | Check Logic's input monitoring |
| High latency | Use Ethernet, reduce buffer size |

## File Locations

```
virtualdrums/
├── midi_bridge/              # Python bridge
│   ├── app.py               # Main server
│   ├── start.sh             # Start script ← RUN THIS
│   └── test_bridge.py       # Tests
│
├── virtualdrums/            # VR app
│   ├── MIDIBridgeClient.swift
│   └── WindowGroup/
│       └── MIDIBridgeSettingsView.swift
│
├── GETTING_STARTED.md       # Full setup guide
├── MIDI_SETUP.md            # Complete docs
└── QUICK_REFERENCE.md       # This file
```

## Logic Pro Quick Setup

1. Track → New Software Instrument
2. Instrument slot → External MIDI → "VRDrumkit Virtual Out"
3. Load drum plugin (Ultrabeat, Drum Kit Designer, etc.)
4. Enable record (R) and monitoring (I)
5. Play!

## URL Configuration

**Same machine (Mac & Simulator):**
```
http://localhost:5729
```

**Vision Pro on network:**
```
http://YOUR_MAC_IP:5729
```

Find your Mac's IP: System Settings → Network

## Essential Endpoints

- `GET /health` - Status check
- `POST /event` - Drum hit: `{drum, velocity, noteOffDelay}`
- `POST /select` - Kit change: `{drumkit?, soundkit?}`

## Keyboard Shortcuts (Logic)

- `R` - Record
- `Space` - Play/Stop
- `C` - Cycle mode
- `I` - Toggle monitoring
- `⌘⇧K` - Show MIDI activity

## Python Environment

```bash
# Activate shell
cd midi_bridge && pipenv shell

# Run directly
pipenv run python app.py

# Check MIDI
pipenv run python check_midi.py

# Install new packages
pipenv install <package>
```

## VR App Settings

1. Open app
2. MIDI Bridge tab
3. Enter bridge URL
4. Test connection
5. Toggle enable/disable

## Quick Test Pattern

```bash
# 4-beat drum pattern
for i in {1..4}; do
  curl -s -X POST http://localhost:5729/event \
    -H "Content-Type: application/json" \
    -d '{"drum":"target_kick","velocity":0.9}' && sleep 0.25
  curl -s -X POST http://localhost:5729/event \
    -H "Content-Type: application/json" \
    -d '{"drum":"target_snare","velocity":0.8}' && sleep 0.25
  curl -s -X POST http://localhost:5729/event \
    -H "Content-Type: application/json" \
    -d '{"drum":"target_hi_hat_closed","velocity":0.5}' && sleep 0.5
done
```

## Performance Tuning

**Low Latency:**
- Logic buffer: 128 samples
- Use Ethernet not WiFi
- Close other apps

**Best Quality:**
- Logic buffer: 512 samples
- High-quality drum plugins
- Post-process with EQ/compression

## Getting Help

1. Read [GETTING_STARTED.md](GETTING_STARTED.md)
2. Run `test_bridge.py`
3. Check console logs
4. Verify MIDI activity in Logic

---

**Quick Start: `./start.sh` → Open Logic → Build VR App → Drum! 🥁**
