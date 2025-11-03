#!/bin/bash
# Run this on your Raspberry Pi to fix the dashboard

set -e

echo "========================================"
echo "FIXING PULSE DASHBOARD AFTER REBOOT"
echo "========================================"
echo ""

cd /opt/pulse

echo "1. Building dashboard UI..."
cd /opt/pulse/dashboard/ui

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "   Installing npm dependencies..."
    npm install
fi

# Build the dashboard
echo "   Building production dashboard..."
npm run build

echo ""
echo "2. Creating dashboard service..."

# Create a simple static server service
sudo tee /etc/systemd/system/pulse-dashboard.service > /dev/null << 'EOF'
[Unit]
Description=Pulse Dashboard Web Server
After=network.target pulse.service
Requires=pulse.service

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/pulse/dashboard/ui
ExecStart=/usr/bin/python3 -m http.server 5173 --directory build
Restart=always
RestartSec=3
StandardOutput=append:/var/log/pulse/dashboard.log
StandardError=append:/var/log/pulse/dashboard-error.log

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "3. Creating hub API service..."

sudo tee /etc/systemd/system/pulse-hub.service > /dev/null << 'EOF'
[Unit]
Description=Pulse Hub API
After=network.target
Requires=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/pulse
Environment="PYTHONPATH=/opt/pulse:/opt/pulse/services"
Environment="PYTHONUNBUFFERED=1"
ExecStart=/opt/pulse/venv/bin/python3 -m uvicorn services.hub.main:app --host 0.0.0.0 --port 7000
Restart=always
RestartSec=5
StandardOutput=append:/var/log/pulse/hub.log
StandardError=append:/var/log/pulse/hub-error.log

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "4. Disabling first-boot wizard..."
sudo systemctl disable pulse-firstboot.service 2>/dev/null || true
sudo systemctl stop pulse.service

echo ""
echo "5. Reloading systemd..."
sudo systemctl daemon-reload

echo ""
echo "6. Enabling services..."
sudo systemctl enable pulse-hub.service
sudo systemctl enable pulse-dashboard.service

echo ""
echo "7. Starting services..."
sudo systemctl start pulse-hub.service
sleep 3
sudo systemctl start pulse-dashboard.service
sleep 5

echo ""
echo "8. Checking status..."
echo ""
echo "Hub API:"
systemctl status pulse-hub.service --no-pager | head -10
echo ""
echo "Dashboard:"
systemctl status pulse-dashboard.service --no-pager | head -10

echo ""
echo "9. Testing connectivity..."
echo ""
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "Testing Hub API (port 7000)..."
curl -s http://localhost:7000/health || echo "   ⚠ Hub not responding yet"
echo ""
echo "Testing Dashboard (port 5173)..."
curl -s -I http://localhost:5173 | head -2 || echo "   ⚠ Dashboard not responding yet"

echo ""
echo "========================================"
echo "✅ FIX COMPLETE!"
echo "========================================"
echo ""
echo "Access your dashboard at:"
echo "   http://$IP_ADDR:5173"
echo ""
echo "If it's not working yet, wait 30 seconds and try again."
echo ""
echo "To check logs:"
echo "   sudo journalctl -u pulse-dashboard.service -f"
echo "   sudo journalctl -u pulse-hub.service -f"
