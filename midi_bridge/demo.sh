#!/bin/bash
# Example HTTP requests to test the MIDI Bridge
# Run this after starting the bridge with ./start.sh

BASE_URL="http://localhost:5729"

echo "🎹 VR Drumkit MIDI Bridge - Example Usage"
echo "=========================================="
echo ""

# Health check
echo "1️⃣ Health Check"
echo "---"
curl -s "$BASE_URL/health" | python3 -m json.tool
echo ""
echo ""

# Drum hit examples
echo "2️⃣ Drum Hit Events"
echo "---"

echo "Snare (velocity 0.8):"
curl -X POST "$BASE_URL/event" \
  -H "Content-Type: application/json" \
  -d '{"drum": "target_snare", "velocity": 0.8}'
echo ""
sleep 0.3

echo "Kick (velocity 1.0):"
curl -X POST "$BASE_URL/event" \
  -H "Content-Type: application/json" \
  -d '{"drum": "target_kick", "velocity": 1.0}'
echo ""
sleep 0.3

echo "Hi-hat closed (velocity 0.6):"
curl -X POST "$BASE_URL/event" \
  -H "Content-Type: application/json" \
  -d '{"drum": "target_hi_hat_closed", "velocity": 0.6}'
echo ""
sleep 0.3

echo "Crash (velocity 0.9):"
curl -X POST "$BASE_URL/event" \
  -H "Content-Type: application/json" \
  -d '{"drum": "target_crash", "velocity": 0.9}'
echo ""
echo ""
sleep 0.5

# Simple drum pattern
echo "3️⃣ Simple Beat Pattern"
echo "---"
for i in {1..4}; do
  # Kick
  curl -s -X POST "$BASE_URL/event" \
    -H "Content-Type: application/json" \
    -d '{"drum": "target_kick", "velocity": 0.9}' > /dev/null
  sleep 0.25
  
  # Snare
  curl -s -X POST "$BASE_URL/event" \
    -H "Content-Type: application/json" \
    -d '{"drum": "target_snare", "velocity": 0.8}' > /dev/null
  sleep 0.25
  
  # Hi-hat
  curl -s -X POST "$BASE_URL/event" \
    -H "Content-Type: application/json" \
    -d '{"drum": "target_hi_hat_closed", "velocity": 0.5}' > /dev/null
  sleep 0.25
  
  # Hi-hat
  curl -s -X POST "$BASE_URL/event" \
    -H "Content-Type: application/json" \
    -d '{"drum": "target_hi_hat_closed", "velocity": 0.5}' > /dev/null
  sleep 0.25
done
echo "✓ Played 4-bar pattern"
echo ""

# Kit selection
echo "4️⃣ Kit Selection"
echo "---"

echo "Switching to electronic drumkit:"
curl -X POST "$BASE_URL/select" \
  -H "Content-Type: application/json" \
  -d '{"drumkit": "electronic"}'
echo ""
sleep 1

echo "Switching to burgundy_drum soundkit:"
curl -X POST "$BASE_URL/select" \
  -H "Content-Type: application/json" \
  -d '{"soundkit": "burgundy_drum"}'
echo ""
sleep 1

echo "Resetting to defaults:"
curl -X POST "$BASE_URL/select" \
  -H "Content-Type: application/json" \
  -d '{"drumkit": "accoustic", "soundkit": "drum_kit"}'
echo ""
echo ""

echo "✅ Demo complete!"
echo ""
echo "💡 Tip: Open Logic Pro and watch the MIDI activity"
echo "   (Window → Show MIDI Activity) while running this script."
