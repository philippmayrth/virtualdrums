#!/usr/bin/env python3
"""
Test the MIDI Bridge connection and functionality
"""

import requests
import time
import sys

BASE_URL = "http://localhost:5729"

def test_health():
    """Test health check endpoint"""
    print("\n🏥 Testing /health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        response.raise_for_status()
        data = response.json()
        print(f"✅ Bridge is running!")
        print(f"   MIDI Port: {data.get('midi_port')}")
        print(f"   Audio: {data.get('audio_enabled')}")
        print(f"   DrumKit: {data.get('current_drumkit')}")
        print(f"   SoundKit: {data.get('current_soundkit')}")
        return True
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_drum_hit():
    """Test drum hit event"""
    print("\n🥁 Testing drum hit events...")
    drums = [
        ("target_snare", 0.8),
        ("target_bass_drum", 1.0),
        ("target_hi_hat_closed", 0.6),
        ("target_crash", 0.9),
    ]
    
    try:
        for drum, velocity in drums:
            print(f"   Hitting {drum} (vel: {velocity})...")
            response = requests.post(
                f"{BASE_URL}/event",
                json={"drum": drum, "velocity": velocity}
            )
            response.raise_for_status()
            time.sleep(0.5)
        print("✅ Drum hits sent successfully")
        return True
    except Exception as e:
        print(f"❌ Drum hit test failed: {e}")
        return False

def test_kit_selection():
    """Test kit selection"""
    print("\n🎨 Testing kit selection...")
    try:
        # Test drumkit change
        print("   Changing to electronic drumkit...")
        response = requests.post(
            f"{BASE_URL}/select",
            json={"drumkit": "electronic"}
        )
        response.raise_for_status()
        time.sleep(0.5)
        
        # Test soundkit change
        print("   Changing to burgundy_drum soundkit...")
        response = requests.post(
            f"{BASE_URL}/select",
            json={"soundkit": "burgundy_drum"}
        )
        response.raise_for_status()
        time.sleep(0.5)
        
        # Change back to defaults
        print("   Resetting to defaults...")
        response = requests.post(
            f"{BASE_URL}/select",
            json={"drumkit": "accoustic", "soundkit": "drum_kit"}
        )
        response.raise_for_status()
        
        print("✅ Kit selection tests passed")
        return True
    except Exception as e:
        print(f"❌ Kit selection test failed: {e}")
        return False

def main():
    print("="*50)
    print("🎹 VR Drumkit MIDI Bridge - Test Suite")
    print("="*50)
    
    # Run tests
    health_ok = test_health()
    if not health_ok:
        print("\n❌ Bridge is not running. Start it with:")
        print("   cd midi_bridge")
        print("   ./start.sh")
        sys.exit(1)
    
    drum_ok = test_drum_hit()
    kit_ok = test_kit_selection()
    
    # Summary
    print("\n" + "="*50)
    print("📊 Test Summary")
    print("="*50)
    print(f"Health Check: {'✅' if health_ok else '❌'}")
    print(f"Drum Hits: {'✅' if drum_ok else '❌'}")
    print(f"Kit Selection: {'✅' if kit_ok else '❌'}")
    
    if health_ok and drum_ok and kit_ok:
        print("\n🎉 All tests passed! Bridge is working correctly.")
        print("\n💡 Next steps:")
        print("   1. Open Logic Pro")
        print("   2. Create a Software Instrument track")
        print("   3. Set MIDI input to 'VRDrumkit Virtual Out'")
        print("   4. Load a drum plugin (e.g., Ultrabeat)")
        print("   5. Start playing in VR!")
    else:
        print("\n⚠️ Some tests failed. Check the bridge logs.")

if __name__ == "__main__":
    main()
