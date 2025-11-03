#!/bin/bash
# Kiosk mode startup for Pulse dashboard

# Wait for dashboard to be ready
sleep 10

# Open in fullscreen kiosk mode
if command -v chromium-browser &>/dev/null; then
    chromium-browser --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble http://localhost:8080
elif command -v chromium &>/dev/null; then
    chromium --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble http://localhost:8080
elif command -v firefox &>/dev/null; then
    firefox --kiosk http://localhost:8080
fi
