#!/bin/bash

echo "=========================================="
echo "FINDING AND FIXING PULSE INSTALLATION"
echo "=========================================="
echo ""

# Find where pulse might be installed
echo "1. Looking for pulse installation..."
echo "---"

# Common locations
LOCATIONS=(
    "/home/pi/pulse"
    "/home/pi/Pulse"
    "/home/pi/workspace"
    "/opt/pulse"
    "/usr/local/pulse"
    "$HOME/pulse"
    "$HOME/Pulse"
)

FOUND=""
for loc in "${LOCATIONS[@]}"; do
    if [ -d "$loc" ] && [ -f "$loc/README.md" ]; then
        echo "✓ Found at: $loc"
        FOUND="$loc"
        break
    fi
done

if [ -z "$FOUND" ]; then
    echo "✗ Not found in common locations. Searching entire home directory..."
    FOUND=$(find ~ -maxdepth 3 -name "run_pulse_system.py" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
    if [ -n "$FOUND" ]; then
        echo "✓ Found at: $FOUND"
    fi
fi

if [ -z "$FOUND" ]; then
    echo "✗ Could not find pulse installation!"
    echo ""
    echo "Where did you clone/download the pulse repository?"
    echo "Current directory: $(pwd)"
    echo "Your home: $HOME"
    echo ""
    echo "Please run this from the pulse directory:"
    echo "  cd /path/to/pulse"
    echo "  sudo ./install.sh"
    exit 1
fi

echo ""
echo "2. Checking what's in the installation..."
echo "---"
ls -la "$FOUND" | head -20
echo ""

echo "3. Checking if install script exists..."
echo "---"
ls -la "$FOUND"/*.sh 2>/dev/null | grep -E "(install|setup|start)"
echo ""

echo "4. Checking current git branch..."
echo "---"
cd "$FOUND" && git branch 2>/dev/null | grep "*"
cd - > /dev/null
echo ""

echo "5. Checking if services directory exists..."
echo "---"
ls -la "$FOUND/services/systemd/" 2>/dev/null | head -10
echo ""

echo "=========================================="
echo "INSTALLATION FOUND AT: $FOUND"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo ""
echo "Option 1 - RUN FULL INSTALL:"
echo "  cd $FOUND"
echo "  sudo ./install.sh"
echo ""
echo "Option 2 - RUN SIMPLIFIED INSTALL:"
echo "  cd $FOUND"
echo "  sudo ./SIMPLE_INSTALL.sh"
echo ""
echo "Option 3 - MANUAL SERVICE INSTALL:"
echo "  cd $FOUND"
echo "  sudo cp services/systemd/*.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable pulse-dashboard.service"
echo "  sudo systemctl start pulse-dashboard.service"
echo ""
