#!/bin/bash
# Quick start script for VR Drumkit MIDI Bridge

echo "🎹 Starting VR Drumkit MIDI Bridge..."
echo ""

# Check if pipenv is installed
if ! command -v pipenv &> /dev/null; then
    echo "❌ pipenv not found. Installing..."
    pip3 install pipenv
fi

# Install dependencies if needed
if [ ! -f "Pipfile.lock" ]; then
    echo "📦 Installing dependencies..."
    pipenv install
fi

echo "✅ Starting bridge server..."
echo "   MIDI Port: VRDrumkit Virtual Out"
echo "   HTTP Server: http://0.0.0.0:5729"
echo ""
echo "Press Ctrl+C to stop"
echo ""

pipenv run python app.py
