#!/usr/bin/env python3
"""
Simple MIDI port tester - verifies python-rtmidi is working
"""

import sys

try:
    import rtmidi
    print("✅ python-rtmidi is installed")
    
    # Check available APIs
    apis = rtmidi.get_compiled_api()
    print(f"✅ Available MIDI APIs: {apis}")
    
    # Try to create output
    midiout = rtmidi.MidiOut()
    print(f"✅ Can create MIDI output")
    
    # Try to open virtual port
    try:
        midiout.open_virtual_port("TestPort")
        print(f"✅ Can create virtual MIDI port")
        print(f"   Port name: TestPort")
        midiout.close_port()
        print(f"✅ Port closed successfully")
    except Exception as e:
        print(f"❌ Failed to create virtual port: {e}")
        sys.exit(1)
    
    print("\n🎉 Your MIDI setup is working correctly!")
    print("\nYou can now run: ./start.sh")
    
except ImportError:
    print("❌ python-rtmidi is not installed")
    print("\nRun: pipenv install")
    sys.exit(1)
except Exception as e:
    print(f"❌ Unexpected error: {e}")
    sys.exit(1)
