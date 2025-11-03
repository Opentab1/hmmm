# 🚀 Quick Fix Reference

## TL;DR

**Problem:** Installer failed at step 11/11 with `NameError: name 'HealthMonitor' is not defined`  
**Cause:** Install script used old API that doesn't exist  
**Fix:** Updated 3 files to use correct hardware detection code  
**Status:** ✅ Fixed and verified  

## One-Line Fix

```bash
curl -fsSL https://raw.githubusercontent.com/Opentab1/hmmm/main/install.sh | sudo bash
```

Just re-run the installer. It will:
- ✅ Clean up the 99% complete installation
- ✅ Use the fixed code
- ✅ Complete step 11 successfully
- ✅ Reboot automatically

**Time:** 5-7 minutes

## What Was Fixed

| File | What Changed |
|------|--------------|
| `install.sh` | Now uses `hardware_detect.main()` instead of non-existent `HealthMonitor` class |
| `pulse-health.service` | Fixed service startup command |
| `TROUBLESHOOTING.md` | Updated documentation |

## Verification Commands

After re-running:

```bash
# Check services
sudo systemctl status pulse pulse-health

# View hardware report  
cat /var/log/pulse/hardware_report.txt

# Access dashboard
# http://your-pi-ip:8080
```

## Files Created

- 📄 `INSTALLATION_FIX.md` - Detailed explanation
- 📄 `FIX_COMPLETE_SUMMARY.md` - Complete summary
- 📄 `QUICK_FIX_REFERENCE.md` - This file
- 🔧 `verify_fix.py` - Test script

## Need Help?

```bash
# Run diagnostics
cd /opt/pulse
./diagnose_sensors.py

# View logs
sudo journalctl -u pulse -f
```

---

**That's it!** Just re-run the installer and you're good to go. 🎉
