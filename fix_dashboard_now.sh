#!/bin/bash

echo "=== EMERGENCY DASHBOARD FIX ==="
echo ""

# Stop any conflicting processes
echo "1. Stopping any existing services..."
sudo systemctl stop pulse-dashboard.service 2>/dev/null
sudo pkill -f "vite" 2>/dev/null
sudo pkill -f "dashboard.*server" 2>/dev/null
sleep 2

# Check if hub is running (it provides the API)
echo "2. Ensuring hub service is running..."
sudo systemctl start pulse-hub.service
sleep 3

# Start dashboard
echo "3. Starting dashboard service..."
sudo systemctl start pulse-dashboard.service
sleep 5

# Check status
echo "4. Checking status..."
echo ""
systemctl status pulse-dashboard.service --no-pager | head -20
echo ""

# Check if port is open
echo "5. Checking if web server is listening..."
sudo netstat -tlnp | grep -E ":(3000|5173|8000)"
echo ""

# Try to access
echo "6. Testing local access..."
curl -I http://localhost:5173 2>&1 | head -5
echo ""

echo "=== DONE ==="
echo ""
echo "If you see a port listening above, try accessing:"
echo "  http://$(hostname -I | awk '{print $1}'):5173"
echo ""
echo "If still not working, run: ./debug_dashboard_after_reboot.sh"
