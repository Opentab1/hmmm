#!/bin/bash

echo "================================"
echo "FIXING PULSE DASHBOARD NOW"
echo "================================"
echo ""

cd /opt/pulse

echo "1. Installing missing dependencies..."
source /opt/pulse/venv/bin/activate
pip install uvicorn --quiet

echo ""
echo "2. Stopping the broken service..."
sudo systemctl stop pulse.service
sleep 2

echo ""
echo "3. Killing any stuck processes..."
pkill -f "run_pulse_system.py" 2>/dev/null || true
pkill -f "dashboard/api/server.py" 2>/dev/null || true

echo ""
echo "4. Starting dashboard manually..."
cd /opt/pulse
/opt/pulse/venv/bin/python3 dashboard/api/server.py > /tmp/dashboard.log 2>&1 &
DASH_PID=$!

echo "   Dashboard started with PID: $DASH_PID"
sleep 3

echo ""
echo "5. Checking if dashboard is accessible..."
timeout 2 bash -c "echo test > /dev/tcp/localhost/9090" 2>&1 && echo "   ✓ Dashboard is LIVE on port 9090!" || echo "   ✗ Dashboard failed to start"

echo ""
echo "6. Starting hub API..."
/opt/pulse/venv/bin/python3 -c "import uvicorn; from services.hub.main import app; uvicorn.run(app, host='0.0.0.0', port=7000)" > /tmp/hub.log 2>&1 &
HUB_PID=$!

echo "   Hub started with PID: $HUB_PID"
sleep 3

echo ""
echo "7. Checking if hub is accessible..."
timeout 2 bash -c "echo test > /dev/tcp/localhost/7000" 2>&1 && echo "   ✓ Hub API is LIVE on port 7000!" || echo "   ✗ Hub failed to start"

echo ""
echo "================================"
echo "SYSTEM STATUS"
echo "================================"
sudo netstat -tlnp | grep -E ":(7000|9090)" || echo "No services listening"

echo ""
echo "================================"
echo "ACCESS YOUR DASHBOARD"
echo "================================"
echo ""
echo "  Dashboard: http://localhost:9090"
echo "  Dashboard: http://172.17.5.254:9090"
echo "  Hub API:   http://localhost:7000"
echo ""
echo "Open one of these URLs in your browser NOW!"
echo ""
echo "To view logs:"
echo "  Dashboard: tail -f /tmp/dashboard.log"
echo "  Hub:       tail -f /tmp/hub.log"
echo ""
