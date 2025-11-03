#!/usr/bin/env python3
"""
Pulse System Runner
Runs both the Hub and Dashboard API in the same process for debugging
"""

import logging
import sys
import os
from pathlib import Path
from threading import Thread
import time

# Auto-detect Pulse installation directory
SCRIPT_DIR = Path(__file__).resolve().parent

# Try common locations
PULSE_DIRS = [
    SCRIPT_DIR,
    Path('/workspace'),
    Path('/opt/pulse'),
    Path.home() / 'pulse',
]

PULSE_ROOT = None
for pd in PULSE_DIRS:
    if (pd / 'services' / 'hub' / 'main.py').exists():
        PULSE_ROOT = pd
        break

if PULSE_ROOT is None:
    print("ERROR: Cannot find Pulse installation!")
    print(f"Searched: {[str(p) for p in PULSE_DIRS]}")
    sys.exit(1)

print(f"Found Pulse at: {PULSE_ROOT}")

# Add paths
sys.path.insert(0, str(PULSE_ROOT))
sys.path.insert(0, str(PULSE_ROOT / 'services'))
os.chdir(str(PULSE_ROOT))

# Setup detailed logging to console
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

def run_hub():
    """Run the FastAPI hub service with uvicorn"""
    logger.info("="*80)
    logger.info("STARTING PULSE HUB (FastAPI)")
    logger.info("Hub API will be available at: http://localhost:7000")
    logger.info("="*80)
    
    try:
        import uvicorn
        from services.hub.main import app
        
        # Run uvicorn server
        uvicorn.run(
            app,
            host='0.0.0.0',
            port=7000,
            log_level='info'
        )
            
    except Exception as e:
        logger.error(f"Hub error: {e}", exc_info=True)

def run_dashboard():
    """Run the Flask dashboard wizard server"""
    # Give hub time to start first
    time.sleep(5)
    
    logger.info("="*80)
    logger.info("STARTING DASHBOARD WIZARD (Flask)")
    logger.info("Dashboard will be available at: http://localhost:9090")
    logger.info("="*80)
    
    try:
        from dashboard.api.server import app
        
        # Run Flask server with retry logic
        for attempt in range(5):
            try:
                app.run(host='0.0.0.0', port=9090, debug=False)
                break
            except OSError as e:
                logger.warning(f"Dashboard bind failed (attempt {attempt+1}/5): {e}")
                time.sleep(2)
    except Exception as e:
        logger.error(f"Dashboard error: {e}", exc_info=True)

def main():
    """Main entry point"""
    logger.info("\n" + "="*80)
    logger.info("PULSE SYSTEM - INTEGRATED STARTUP")
    logger.info("="*80)
    logger.info("Hub API (FastAPI) will run on: http://localhost:7000")
    logger.info("Dashboard Wizard (Flask) will run on: http://localhost:9090")
    logger.info("="*80 + "\n")
    
    # Create log directory
    os.makedirs("/var/log/pulse", exist_ok=True)
    os.makedirs("/opt/pulse/data", exist_ok=True)
    
    # Start hub in separate thread
    hub_thread = Thread(target=run_hub, daemon=True)
    hub_thread.start()
    
    # Start dashboard in main thread (blocks)
    try:
        run_dashboard()
    except KeyboardInterrupt:
        logger.info("\n" + "="*80)
        logger.info("SHUTTING DOWN PULSE SYSTEM")
        logger.info("="*80)
        sys.exit(0)

if __name__ == "__main__":
    main()
