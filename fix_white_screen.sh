#!/bin/bash
# Emergency White Screen Recovery Script
# This script kills the frozen browser and restarts Pulse services properly

echo "=========================================="
echo "PULSE WHITE SCREEN RECOVERY"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Step 1: Kill the frozen browser
echo -e "${YELLOW}Step 1: Killing frozen browser...${NC}"
pkill -9 chromium-browser 2>/dev/null || true
pkill -9 chromium 2>/dev/null || true
pkill -9 firefox 2>/dev/null || true
sleep 1
echo -e "${GREEN}✓ Browser killed${NC}"
echo ""

# Step 2: Kill any running Pulse processes
echo -e "${YELLOW}Step 2: Stopping existing Pulse processes...${NC}"
pkill -f "python.*hub/main.py" 2>/dev/null || true
pkill -f "python.*dashboard/api/server.py" 2>/dev/null || true
pkill -f "python.*services/hub/main.py" 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Processes stopped${NC}"
echo ""

# Step 3: Create necessary directories
echo -e "${YELLOW}Step 3: Creating necessary directories...${NC}"
sudo mkdir -p /var/log/pulse
sudo mkdir -p /opt/pulse/data
sudo mkdir -p /opt/pulse/config
sudo chown -R $USER:$USER /var/log/pulse /opt/pulse 2>/dev/null || true
echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# Step 4: Set up environment
echo -e "${YELLOW}Step 4: Setting up environment...${NC}"
PULSE_DIR="/workspace"
cd "$PULSE_DIR"
export PYTHONPATH="$PULSE_DIR:$PULSE_DIR/services"

# Determine Python executable
if [ -f "$PULSE_DIR/venv/bin/python3" ]; then
    PYTHON="$PULSE_DIR/venv/bin/python3"
    PIP="$PULSE_DIR/venv/bin/pip3"
elif [ -f "/opt/pulse/venv/bin/python3" ]; then
    PYTHON="/opt/pulse/venv/bin/python3"
    PIP="/opt/pulse/venv/bin/pip3"
else
    PYTHON="python3"
    PIP="pip3"
fi
echo -e "${GREEN}✓ Using Python: $PYTHON${NC}"

# Check if Flask is installed
if ! $PYTHON -c "import flask" 2>/dev/null; then
    echo -e "${YELLOW}Flask not found, installing dependencies...${NC}"
    if [ -f "$PULSE_DIR/requirements.txt" ]; then
        $PIP install -q -r "$PULSE_DIR/requirements.txt" 2>&1 | tail -5
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Dependencies installed${NC}"
        else
            echo -e "${RED}✗ Failed to install dependencies${NC}"
            echo -e "${YELLOW}Try manually: pip3 install -r requirements.txt${NC}"
        fi
    else
        echo -e "${YELLOW}Installing Flask manually...${NC}"
        $PIP install -q flask flask-cors pyyaml cryptography 2>&1 | tail -5
        echo -e "${GREEN}✓ Basic dependencies installed${NC}"
    fi
else
    echo -e "${GREEN}✓ Dependencies already installed${NC}"
fi
echo ""

# Step 5: Check if we should run wizard or dashboard
echo -e "${YELLOW}Step 5: Determining which service to start...${NC}"
WIZARD_COMPLETE="/opt/pulse/config/.wizard_complete"

if [ ! -f "$WIZARD_COMPLETE" ]; then
    echo -e "${CYAN}First boot detected - will start setup wizard on port 9090${NC}"
    SERVICE_TYPE="wizard"
    PORT=9090
    URL="http://localhost:9090"
else
    echo -e "${CYAN}Setup complete - will start dashboard on port 8080${NC}"
    SERVICE_TYPE="dashboard"
    PORT=8080
    URL="http://localhost:8080"
fi
echo ""

# Step 6: Start the appropriate service
echo -e "${YELLOW}Step 6: Starting services...${NC}"

if [ "$SERVICE_TYPE" = "wizard" ]; then
    # Start wizard
    echo -e "${CYAN}Starting setup wizard...${NC}"
    $PYTHON dashboard/api/server.py > /var/log/pulse/wizard.log 2>&1 &
    WIZARD_PID=$!
    echo "$WIZARD_PID" > /tmp/pulse-wizard.pid
    echo -e "${GREEN}✓ Wizard started (PID: $WIZARD_PID)${NC}"
else
    # Start hub
    echo -e "${CYAN}Starting hub...${NC}"
    $PYTHON services/hub/main.py > /var/log/pulse/hub.log 2>&1 &
    HUB_PID=$!
    echo "$HUB_PID" > /tmp/pulse-hub.pid
    echo -e "${GREEN}✓ Hub started (PID: $HUB_PID)${NC}"
    
    # Start dashboard
    echo -e "${CYAN}Starting dashboard...${NC}"
    $PYTHON dashboard/api/server.py > /var/log/pulse/dashboard.log 2>&1 &
    DASHBOARD_PID=$!
    echo "$DASHBOARD_PID" > /tmp/pulse-dashboard.pid
    echo -e "${GREEN}✓ Dashboard started (PID: $DASHBOARD_PID)${NC}"
fi
echo ""

# Step 7: Wait for service to be ready
echo -e "${YELLOW}Step 7: Waiting for service to be ready...${NC}"
RETRIES=0
MAX_RETRIES=30
while [ $RETRIES -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:$PORT > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Service is ready!${NC}"
        break
    fi
    echo -n "."
    sleep 1
    RETRIES=$((RETRIES + 1))
done
echo ""

if [ $RETRIES -eq $MAX_RETRIES ]; then
    echo -e "${RED}✗ Service failed to start. Check logs:${NC}"
    echo -e "  tail -f /var/log/pulse/*.log"
    exit 1
fi

# Step 8: Open browser
echo -e "${YELLOW}Step 8: Opening browser...${NC}"

# Detect browser
if command -v chromium-browser >/dev/null 2>&1; then
    BROWSER="chromium-browser"
elif command -v chromium >/dev/null 2>&1; then
    BROWSER="chromium"
elif command -v firefox >/dev/null 2>&1; then
    BROWSER="firefox"
else
    echo -e "${YELLOW}No browser found. Please manually open: $URL${NC}"
    exit 0
fi

# Open browser (not in kiosk mode for now)
DISPLAY=:0 $BROWSER $URL >/dev/null 2>&1 &
echo -e "${GREEN}✓ Browser opened to $URL${NC}"
echo ""

echo -e "${GREEN}=========================================="
echo -e "RECOVERY COMPLETE!"
echo -e "==========================================${NC}"
echo -e "${CYAN}Service URL: ${NC}$URL"
echo ""
echo -e "${CYAN}To view logs:${NC}"
echo -e "  tail -f /var/log/pulse/*.log"
echo ""
echo -e "${CYAN}To stop services:${NC}"
echo -e "  pkill -f python.*hub"
echo -e "  pkill -f python.*dashboard"
echo ""
echo -e "${GREEN}You should now see the Pulse interface loading!${NC}"
