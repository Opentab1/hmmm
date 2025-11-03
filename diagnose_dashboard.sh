#!/bin/bash

echo "================================"
echo "PULSE DASHBOARD DIAGNOSTICS"
echo "================================"
echo ""

echo "1. CHECKING RUNNING PROCESSES"
echo "--------------------------------"
ps aux | grep -E "(python|node|vite|dashboard)" | grep -v grep
echo ""

echo "2. CHECKING PORT USAGE"
echo "--------------------------------"
echo "Checking ports 3000, 5000, 5173, 8000..."
netstat -tlnp 2>/dev/null | grep -E ":(3000|5000|5173|8000)" || ss -tlnp 2>/dev/null | grep -E ":(3000|5000|5173|8000)"
echo ""

echo "3. CHECKING SYSTEMD SERVICES"
echo "--------------------------------"
systemctl list-units --type=service --all | grep pulse || echo "No systemd pulse services found"
echo ""

echo "4. CHECKING DASHBOARD API SERVER"
echo "--------------------------------"
if [ -f "/workspace/dashboard/api/server.py" ]; then
    echo "Dashboard API file exists"
    echo "Checking if server is running..."
    pgrep -f "dashboard/api/server.py" && echo "API server process found" || echo "API server NOT running"
else
    echo "Dashboard API file NOT FOUND"
fi
echo ""

echo "5. CHECKING DASHBOARD UI"
echo "--------------------------------"
if [ -d "/workspace/dashboard/ui" ]; then
    echo "Dashboard UI directory exists"
    ls -la /workspace/dashboard/ui/dist 2>/dev/null && echo "Build exists" || echo "No build found"
    [ -f "/workspace/dashboard/ui/package.json" ] && echo "package.json exists" || echo "package.json NOT FOUND"
else
    echo "Dashboard UI directory NOT FOUND"
fi
echo ""

echo "6. CHECKING RECENT LOGS (last 50 lines)"
echo "--------------------------------"
if [ -d "/var/log" ]; then
    echo "Checking system logs for dashboard errors..."
    journalctl -u pulse-dashboard -n 50 --no-pager 2>/dev/null || echo "No pulse-dashboard systemd logs"
fi
echo ""

echo "7. TESTING LOCALHOST CONNECTIVITY"
echo "--------------------------------"
echo "Testing port 5000..."
timeout 2 bash -c "</dev/tcp/localhost/5000" 2>/dev/null && echo "Port 5000: OPEN" || echo "Port 5000: CLOSED"
echo "Testing port 3000..."
timeout 2 bash -c "</dev/tcp/localhost/3000" 2>/dev/null && echo "Port 3000: OPEN" || echo "Port 3000: CLOSED"
echo "Testing port 5173..."
timeout 2 bash -c "</dev/tcp/localhost/5173" 2>/dev/null && echo "Port 5173: OPEN" || echo "Port 5173: CLOSED"
echo ""

echo "8. CHECKING NETWORK INTERFACES"
echo "--------------------------------"
ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "Could not determine network config"
echo ""

echo "9. CHECKING IF NODE/NPM ARE INSTALLED"
echo "--------------------------------"
which node && node --version || echo "Node NOT installed"
which npm && npm --version || echo "NPM NOT installed"
echo ""

echo "10. CHECKING PYTHON PROCESSES"
echo "--------------------------------"
ps aux | grep python | grep -v grep
echo ""

echo "11. CHECKING FOR ERROR LOGS IN WORKSPACE"
echo "--------------------------------"
if [ -f "/workspace/dashboard_error.log" ]; then
    echo "Dashboard error log found:"
    tail -n 30 /workspace/dashboard_error.log
else
    echo "No dashboard_error.log found"
fi
echo ""

echo "12. CHECKING FIREWALL STATUS"
echo "--------------------------------"
sudo ufw status 2>/dev/null || iptables -L -n 2>/dev/null | head -20 || echo "Could not check firewall"
echo ""

echo "================================"
echo "DIAGNOSTICS COMPLETE"
echo "================================"
