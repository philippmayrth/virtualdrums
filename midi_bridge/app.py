#!/usr/bin/env python3
"""
VR Drumkit MIDI Bridge
Receives HTTP events from VR app and converts to MIDI + optional audio
"""

import asyncio
import json
from pathlib import Path
from typing import Dict, Optional

import pygame.mixer
import rtmidi
from quart import Quart, request, jsonify

app = Quart(__name__)

# =======================
# MIDI Configuration
# =======================

# MIDI note mapping for drums
DRUM_MIDI_MAP = {
    "target_snare": 38,           # Snare
    "target_kick": 36,            # Kick
    "target_floor_tom": 41,       # Floor tom
    "target_mid_tom": 47,         # Mid tom
    "target_high_tom": 50,        # High tom
    "target_hi_hat_closed": 42,   # Closed hi-hat
    "target_hi_hat_open": 46,     # Open hi-hat
    "target_hi_hat_chick": 44,    # Pedal hi-hat
    "target_ride": 51,            # Ride cymbal
    "target_crash": 49,           # Crash cymbal
}

# Kit selection mappings
DRUMKIT_CC_MAP = {
    "accoustic": 0,
    "electronic": 1,
    "alternative": 2,
}

SOUNDKIT_PROGRAM_MAP = {
    "drum_kit": 0,
    "burgundy_drum": 1,
}


class MIDIBridge:
    """Manages MIDI output and local audio playback"""
    
    def __init__(self, port_name: str = "VRDrumkit Virtual Out"):
        self.port_name = port_name
        self.midiout: Optional[rtmidi.MidiOut] = None
        
        # State
        self.current_drumkit = "accoustic"
        self.current_soundkit = "drum_kit"
        
        # Audio players (optional local playback)
        self.audio_enabled = False
        self.audio_samples: Dict[str, pygame.mixer.Sound] = {}
        
    def setup_midi(self):
        """Create virtual MIDI output port"""
        try:
            self.midiout = rtmidi.MidiOut()
            self.midiout.open_virtual_port(self.port_name)
            print(f"✅ Created virtual MIDI port: {self.port_name}")
        except Exception as e:
            print(f"❌ Failed to create MIDI port: {e}")
            raise
    
    def setup_audio(self, soundkit_path: Optional[Path] = None):
        """Initialize pygame mixer for local audio playback (optional)"""
        try:
            pygame.mixer.init(frequency=44100, size=-16, channels=2, buffer=512)
            pygame.mixer.set_num_channels(32)  # Support polyphony
            self.audio_enabled = True
            print(f"✅ Audio system initialized (32 channels)")
            
            # Load samples if path provided
            if soundkit_path and soundkit_path.exists():
                self._load_soundkit(soundkit_path)
        except Exception as e:
            print(f"⚠️ Audio initialization failed: {e}")
            self.audio_enabled = False
    
    def _load_soundkit(self, soundkit_path: Path):
        """Load audio samples from a soundkit directory"""
        for drum_id in DRUM_MIDI_MAP.keys():
            # Try common extensions
            for ext in ['.aif', '.wav', '.mp3', '.m4a', '.aiff']:
                sample_file = soundkit_path / f"{self.current_drumkit}_{drum_id}{ext}"
                if sample_file.exists():
                    try:
                        self.audio_samples[drum_id] = pygame.mixer.Sound(str(sample_file))
                        print(f"  Loaded: {sample_file.name}")
                        break
                    except Exception as e:
                        print(f"  ⚠️ Failed to load {sample_file.name}: {e}")
    
    def send_note_on(self, note: int, velocity: int, channel: int = 9):
        """Send MIDI Note On (channel 9 = drums)"""
        if self.midiout:
            # MIDI message: [0x90 | channel, note, velocity]
            msg = [0x90 | channel, note & 0x7F, velocity & 0x7F]
            self.midiout.send_message(msg)
    
    def send_note_off(self, note: int, channel: int = 9):
        """Send MIDI Note Off"""
        if self.midiout:
            msg = [0x80 | channel, note & 0x7F, 0]
            self.midiout.send_message(msg)
    
    def send_program_change(self, program: int, channel: int = 9):
        """Send MIDI Program Change (for soundkit selection)"""
        if self.midiout:
            msg = [0xC0 | channel, program & 0x7F]
            self.midiout.send_message(msg)
            print(f"🎵 MIDI Program Change: {program}")
    
    def send_cc(self, cc_number: int, value: int, channel: int = 9):
        """Send MIDI CC (for drumkit selection)"""
        if self.midiout:
            msg = [0xB0 | channel, cc_number & 0x7F, value & 0x7F]
            self.midiout.send_message(msg)
            print(f"🎛️ MIDI CC #{cc_number}: {value}")
    
    def play_audio(self, drum_id: str, velocity: float = 1.0):
        """Play local audio sample (optional demo)"""
        if self.audio_enabled and drum_id in self.audio_samples:
            sound = self.audio_samples[drum_id]
            sound.set_volume(velocity)
            sound.play()
    
    def handle_drum_hit(self, drum_id: str, velocity: float, note_off_delay: float = 0.1):
        """Process a drum hit: MIDI + optional audio"""
        if drum_id not in DRUM_MIDI_MAP:
            print(f"⚠️ Unknown drum ID: {drum_id}")
            return
        
        note = DRUM_MIDI_MAP[drum_id]
        midi_velocity = int(velocity * 127)
        
        # Send MIDI Note On
        self.send_note_on(note, midi_velocity)
        print(f"🥁 {drum_id} → MIDI Note {note} (vel: {midi_velocity})")
        
        # Optional: Play local audio
        self.play_audio(drum_id, velocity)
        
        # Schedule Note Off
        asyncio.create_task(self._delayed_note_off(note, note_off_delay))
    
    async def _delayed_note_off(self, note: int, delay: float):
        """Send Note Off after a delay"""
        await asyncio.sleep(delay)
        self.send_note_off(note)
    
    def select_drumkit(self, drumkit: str):
        """Change visual drumkit (sends CC 20)"""
        if drumkit in DRUMKIT_CC_MAP:
            self.current_drumkit = drumkit
            cc_value = DRUMKIT_CC_MAP[drumkit]
            self.send_cc(cc_number=20, value=cc_value)
            print(f"🎨 DrumKit selected: {drumkit}")
        else:
            print(f"⚠️ Unknown drumkit: {drumkit}")
    
    def select_soundkit(self, soundkit: str):
        """Change audio soundkit (sends Program Change)"""
        if soundkit in SOUNDKIT_PROGRAM_MAP:
            self.current_soundkit = soundkit
            program = SOUNDKIT_PROGRAM_MAP[soundkit]
            self.send_program_change(program)
            print(f"🎵 SoundKit selected: {soundkit}")
        else:
            print(f"⚠️ Unknown soundkit: {soundkit}")
    
    def cleanup(self):
        """Close MIDI port"""
        if self.midiout:
            self.midiout.close_port()
            print("🔌 MIDI port closed")


# =======================
# Global Bridge Instance
# =======================

bridge = MIDIBridge()


# =======================
# HTTP Endpoints
# =======================

@app.route('/health', methods=['GET'])
async def health():
    """Health check endpoint"""
    return jsonify({
        "status": "ok",
        "midi_port": bridge.port_name,
        "audio_enabled": bridge.audio_enabled,
        "current_drumkit": bridge.current_drumkit,
        "current_soundkit": bridge.current_soundkit,
    })


@app.route('/event', methods=['POST'])
async def handle_event():
    """
    Handle drum hit events from VR app
    
    Expected JSON payload:
    {
        "drum": "target_snare",
        "velocity": 0.85,
        "noteOffDelay": 0.1  // optional, default 0.1
    }
    """
    try:
        data = await request.get_json()
        
        drum_id = data.get('drum')
        velocity = data.get('velocity', 1.0)
        note_off_delay = data.get('noteOffDelay', 0.1)
        
        if not drum_id:
            return jsonify({"error": "Missing 'drum' field"}), 400
        
        # Clamp velocity to [0, 1]
        velocity = max(0.0, min(1.0, float(velocity)))
        
        # Process the drum hit
        bridge.handle_drum_hit(drum_id, velocity, note_off_delay)
        
        return jsonify({"status": "ok", "drum": drum_id, "velocity": velocity})
    
    except Exception as e:
        print(f"❌ Error handling event: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/select', methods=['POST'])
async def handle_selection():
    """
    Handle kit selection changes
    
    Expected JSON payload:
    {
        "drumkit": "electronic",    // optional: visual model
        "soundkit": "burgundy_drum" // optional: audio set
    }
    """
    try:
        data = await request.get_json()
        
        drumkit = data.get('drumkit')
        soundkit = data.get('soundkit')
        
        if drumkit:
            bridge.select_drumkit(drumkit)
        
        if soundkit:
            bridge.select_soundkit(soundkit)
        
        return jsonify({
            "status": "ok",
            "current_drumkit": bridge.current_drumkit,
            "current_soundkit": bridge.current_soundkit,
        })
    
    except Exception as e:
        print(f"❌ Error handling selection: {e}")
        return jsonify({"error": str(e)}), 500


# =======================
# Startup & Shutdown
# =======================

@app.before_serving
async def startup():
    """Initialize MIDI and audio systems"""
    print("\n" + "="*50)
    print("🎹 VR Drumkit MIDI Bridge Starting...")
    print("="*50)
    
    # Setup MIDI
    bridge.setup_midi()
    
    # Setup audio (optional - provide path to your soundkit)
    # Example: soundkit_path = Path(__file__).parent.parent / "virtualdrums/assets/soundkit/accoustic"
    # bridge.setup_audio(soundkit_path)
    bridge.setup_audio()  # Initialize without samples for now
    
    print("\n✅ Bridge ready! Listening for VR events...\n")


@app.after_serving
async def shutdown():
    """Cleanup resources"""
    print("\n🔌 Shutting down...")
    bridge.cleanup()


# =======================
# Main Entry Point
# =======================

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5729, debug=False)
