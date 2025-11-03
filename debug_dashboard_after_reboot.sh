#!/bin/bash

echo "=========================================="
echo "PULSE DASHBOARD POST-REBOOT DIAGNOSTICS"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}[1/10] Checking systemd services status...${NC}"
echo "---"
systemctl status pulse-dashboard.service --no-pager
echo ""
systemctl status pulse-hub.service --no-pager
echo ""
systemctl is-enabled pulse-dashboard.service
systemctl is-enabled pulse-hub.service
echo ""

echo -e "${YELLOW}[2/10] Checking if services are running...${NC}"
echo "---"
systemctl is-active pulse-dashboard.service && echo -e "${GREEN}Dashboard: ACTIVE${NC}" || echo -e "${RED}Dashboard: INACTIVE${NC}"
systemctl is-active pulse-hub.service && echo -e "${GREEN}Hub: ACTIVE${NC}" || echo -e "${RED}Hub: INACTIVE${NC}"
echo ""

echo -e "${YELLOW}[3/10] Checking for dashboard processes...${NC}"
echo "---"
ps aux | grep -E "(dashboard|vite|node)" | grep -v grep
echo ""

echo -e "${YELLOW}[4/10] Checking network ports (dashboard should be on 5173 or 3000)...${NC}"
echo "---"
sudo netstat -tlnp | grep -E ":(3000|5173|8000|5000)" || echo "No processes listening on dashboard ports!"
echo ""

echo -e "${YELLOW}[5/10] Checking last 50 lines of dashboard logs...${NC}"
echo "---"
sudo journalctl -u pulse-dashboard.service -n 50 --no-pager
echo ""

echo -e "${YELLOW}[6/10] Checking last 50 lines of hub logs...${NC}"
echo "---"
sudo journalctl -u pulse-hub.service -n 50 --no-pager
echo ""

echo -e "${YELLOW}[7/10] Checking dashboard API server status...${NC}"
echo "---"
ps aux | grep -E "dashboard.*server" | grep -v grep
curl -s http://localhost:8000/health 2>&1 || echo "API server not responding"
echo ""

echo -e "${YELLOW}[8/10] Checking if dashboard files exist...${NC}"
echo "---"
ls -la /workspace/dashboard/ui/ 2>&1 | head -20
echo ""
ls -la /workspace/dashboard/api/ 2>&1
echo ""

echo -e "${YELLOW}[9/10] Checking network connectivity...${NC}"
echo "---"
ip addr show | grep "inet "
echo ""

echo -e "${YELLOW}[10/10] Checking for errors in system logs (last 100 lines)...${NC}"
echo "---"
sudo journalctl --since "5 minutes ago" --no-pager | grep -iE "(error|fail|dashboard)" | tail -50
echo ""

echo "=========================================="
echo -e "${GREEN}QUICK DIAGNOSTIC COMPLETE!${NC}"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo "1. Copy ALL output above"
echo "2. Check which services are INACTIVE (red)"
echo "3. Look for errors in the logs"
echo ""

# Quick summary
echo "=== QUICK SUMMARY ==="
DASH_ACTIVE=$(systemctl is-active pulse-dashboard.service 2>/dev/null)
HUB_ACTIVE=$(systemctl is-active pulse-hub.service 2>/dev/null)
PORT_CHECK=$(sudo netstat -tlnp 2>/dev/null | grep -E ":(3000|5173)" | wc -l)

echo "Dashboard Service: $DASH_ACTIVE"
echo "Hub Service: $HUB_ACTIVE"
echo "Ports listening: $PORT_CHECK"

if [ "$DASH_ACTIVE" != "active" ]; then
    echo -e "${RED}⚠ Dashboard service is NOT running!${NC}"
    echo "Try: sudo systemctl start pulse-dashboard.service"
fi

if [ $PORT_CHECK -eq 0 ]; then
    echo -e "${RED}⚠ No web server listening on expected ports!${NC}"
fi
