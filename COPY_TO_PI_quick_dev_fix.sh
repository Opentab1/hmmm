#!/bin/bash
# Quick fix - runs dashboard in DEV mode (faster to get running)
# Run this on your Raspberry Pi

set -e

echo "========================================"
echo "QUICK DEV MODE FIX"
echo "========================================"
echo ""

cd /opt/pulse/dashboard/ui

echo "1. Installing dependencies (if needed)..."
if [ ! -d "node_modules" ]; then
    npm install
fi

echo ""
echo "2. Fixing API proxy configuration..."

# Update vite config to point to correct API port (7000)
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'build'
  },
  server: {
    host: '0.0.0.0',
    port: 5173,
    proxy: {
      '/api': 'http://localhost:7000',
      '/socket.io': {
        target: 'http://localhost:7000',
        ws: true
      }
    }
  }
})
EOF

echo ""
echo "3. Creating run script..."

cat > /opt/pulse/run_dashboard_dev.sh << 'EOF'
#!/bin/bash
cd /opt/pulse/dashboard/ui
exec npm run dev
EOF

chmod +x /opt/pulse/run_dashboard_dev.sh

echo ""
echo "4. Creating systemd service for dashboard..."

sudo tee /etc/systemd/system/pulse-dashboard.service > /dev/null << 'EOF'
[Unit]
Description=Pulse Dashboard Web Server (Dev Mode)
After=network.target pulse-hub.service
Requires=pulse-hub.service

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/pulse/dashboard/ui
Environment="NODE_ENV=development"
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=3
StandardOutput=append:/var/log/pulse/dashboard.log
StandardError=append:/var/log/pulse/dashboard-error.log

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "5. Creating hub service..."

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
echo "6. Stopping old pulse service..."
sudo systemctl stop pulse.service 2>/dev/null || true
sudo systemctl disable pulse-firstboot.service 2>/dev/null || true

echo ""
echo "7. Reloading and enabling new services..."
sudo systemctl daemon-reload
sudo systemctl enable pulse-hub.service
sudo systemctl enable pulse-dashboard.service

echo ""
echo "8. Starting services..."
sudo systemctl start pulse-hub.service
sleep 3
sudo systemctl start pulse-dashboard.service
echo "   (Dashboard takes 10-20 seconds to start in dev mode...)"
sleep 10

echo ""
echo "9. Checking status..."
echo ""
echo "=== Hub Status ==="
systemctl is-active pulse-hub.service && echo "✓ RUNNING" || echo "✗ FAILED"
echo ""
echo "=== Dashboard Status ==="
systemctl is-active pulse-dashboard.service && echo "✓ RUNNING" || echo "✗ FAILED"

echo ""
echo "10. Checking ports..."
sudo netstat -tlnp | grep -E ":(5173|7000)" || echo "⚠ Ports not listening yet"

echo ""
echo "========================================"
echo "✅ SETUP COMPLETE!"
echo "========================================"
echo ""
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "Your dashboard should be accessible at:"
echo "   http://$IP_ADDR:5173"
echo ""
echo "Note: First load may take 20-30 seconds!"
echo ""
echo "To check logs in real-time:"
echo "   sudo journalctl -u pulse-dashboard.service -f"
echo ""
echo "To check hub API:"
echo "   sudo journalctl -u pulse-hub.service -f"
