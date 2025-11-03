# 🆘 IMMEDIATE WHITE SCREEN ESCAPE INSTRUCTIONS

## You're Stuck on "Site Can't Be Reached" - Here's How to Fix It

### The Problem
Your browser opened to `localhost:8080` but the dashboard server never started, so you're staring at a white screen. The services didn't launch properly.

---

## ⚡ QUICK FIX (Choose ONE method)

### Method 1: If You Can See the URL Bar (EASIEST)
1. **Press `ESC`** on your keyboard to exit fullscreen
2. **Press `ALT+F4`** or click the X to close the browser
3. Open a terminal and run:
```bash
cd /workspace
./fix_white_screen.sh
```

### Method 2: If You're Stuck in Fullscreen
1. **Press `ALT+F4`** to force-close the browser
   - If that doesn't work, try `CTRL+W`
   - Still stuck? Try `CTRL+ALT+F2` to switch to a terminal
2. Run the recovery script:
```bash
cd /workspace
./fix_white_screen.sh
```

### Method 3: From Terminal (If on Remote/SSH)
```bash
cd /workspace
./fix_white_screen.sh
```

---

## 🔍 What Went Wrong?

The startup script (`start_pulse.sh`) tried to:
1. ✅ Start the dashboard server
2. ✅ Open a browser to localhost:8080
3. ❌ But the server failed to start (likely missing directories or permissions)
4. ❌ Browser opened anyway to a non-existent page = white screen

---

## 🛠️ What the Recovery Script Does

The `fix_white_screen.sh` script will:
1. ✅ Kill the frozen browser
2. ✅ Stop any partial/failed Pulse processes
3. ✅ Create all necessary directories (`/var/log/pulse`, `/opt/pulse`)
4. ✅ Detect if it's first boot (needs wizard) or normal boot (needs dashboard)
5. ✅ Start the correct service on the correct port
6. ✅ Wait for the service to be ready
7. ✅ Open a working browser to the correct URL

---

## 📋 After Running the Script

You should see:
- ✅ Green checkmarks for each step
- ✅ "Service is ready!" message
- ✅ Browser opens to either:
  - Port 9090 (setup wizard) - if first boot
  - Port 8080 (dashboard) - if already configured

---

## 🐛 If the Script Fails

1. **Check the logs:**
```bash
tail -f /var/log/pulse/*.log
```

2. **Verify Python is installed:**
```bash
python3 --version
```

3. **Check if venv exists:**
```bash
ls -la /workspace/venv/
```

4. **Try manual startup:**
```bash
cd /workspace
export PYTHONPATH="/workspace:/workspace/services"
python3 services/hub/main.py
# In another terminal:
python3 dashboard/api/server.py
```

---

## 💡 Prevention for Next Time

The issue is that the startup script doesn't properly wait for services or check if directories exist. The recovery script fixes this, but for a permanent fix, we should:

1. Update `start_pulse.sh` to include better error checking
2. Ensure directories are created before starting services
3. Add retry logic for service startup
4. Check if ports are already in use

---

## 📞 Need More Help?

- View logs: `tail -f /var/log/pulse/*.log`
- Check processes: `ps aux | grep python`
- Kill everything: `pkill -f python.*pulse`
- Full docs: See `TROUBLESHOOTING.md` and `WHITE_SCREEN_FIX.md`

---

**TL;DR: Close the browser (`ALT+F4`), run `./fix_white_screen.sh`, and you'll be back up and running! 🚀**
