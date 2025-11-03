#!/bin/bash

echo "=========================================="
echo "INVESTIGATING EXISTING PULSE SERVICES"
echo "=========================================="
echo ""

echo "1. Checking pulse service files..."
echo "---"
for service in pulse.service pulse-firstboot.service pulse-health.service; do
    echo "=== $service ==="
    if [ -f "/etc/systemd/system/$service" ]; then
        cat "/etc/systemd/system/$service"
    elif [ -f "/lib/systemd/system/$service" ]; then
        cat "/lib/systemd/system/$service"
    else
        echo "Not found in usual locations"
    fi
    echo ""
done

echo "2. Checking service status..."
echo "---"
sudo systemctl status pulse.service --no-pager -l
echo ""
sudo systemctl status pulse-firstboot.service --no-pager -l
echo ""

echo "3. Looking for any pulse-related processes..."
echo "---"
ps aux | grep -i pulse | grep -v grep
echo ""

echo "4. Checking recent logs from pulse services..."
echo "---"
sudo journalctl -u pulse.service -n 50 --no-pager
echo ""

echo "5. Searching for any pulse directories system-wide..."
echo "---"
sudo find / -type d -name "*pulse*" 2>/dev/null | grep -v -E "(lib|proc|sys|run|dev)" | head -20
echo ""

echo "6. Checking if there's a web server running..."
echo "---"
sudo netstat -tlnp | grep LISTEN
echo ""

echo "=========================================="
echo "INVESTIGATION COMPLETE"
echo "=========================================="
