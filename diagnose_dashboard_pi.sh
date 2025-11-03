#!/bin/bash

echo "================================"
echo "PULSE DASHBOARD DIAGNOSTICS"
echo "================================"
echo ""

echo "CURRENT LOCATION: $(pwd)"
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

echo "4. CHECKING FOR PULSE PROJECT"
echo "--------------------------------"
find ~ -name "run_pulse_system.py" -o -name "start_pulse.sh" 2>/dev/null | head -5
echo ""

echo "5. TESTING LOCALHOST CONNECTIVITY"
echo "--------------------------------"
echo "Testing port 5000..."
timeout 2 bash -c "</dev/tcp/localhost/5000" 2>/dev/null && echo "Port 5000: OPEN" || echo "Port 5000: CLOSED"
echo "Testing port 3000..."
timeout 2 bash -c "</dev/tcp/localhost/3000" 2>/dev/null && echo "Port 3000: OPEN" || echo "Port 3000: CLOSED"
echo "Testing port 5173..."
timeout 2 bash -c "</dev/tcp/localhost/5173" 2>/dev/null && echo "Port 5173: OPEN" || echo "Port 5173: CLOSED"
echo ""

echo "6. CHECKING NETWORK INTERFACES"
echo "--------------------------------"
ip addr show 2>/dev/null | grep -E "inet |UP"
echo ""

echo "7. CHECKING RECENT JOURNAL LOGS"
echo "--------------------------------"
journalctl -n 50 --no-pager 2>/dev/null | grep -i "pulse\|dashboard\|error" | tail -20 || echo "No journal access"
echo ""

echo "8. WHAT DID YOU RUN TO START?"
echo "--------------------------------"
history | tail -20
echo ""

echo "================================"
echo "DIAGNOSTICS COMPLETE"
echo "================================"
