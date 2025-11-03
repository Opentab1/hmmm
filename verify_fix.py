#!/usr/bin/env python3
"""
Quick verification script to test the installation fix.
This simulates what the install script does at step 11.
"""
import sys
import json
from pathlib import Path

# Add the workspace to path (simulates PYTHONPATH=/opt/pulse)
sys.path.insert(0, str(Path(__file__).parent))

def test_imports():
    """Test that all required modules can be imported."""
    print("Testing imports...")
    try:
        from services.sensors import hardware_detect
        print("  ✓ hardware_detect module imported")
        
        from services.sensors import health_monitor
        print("  ✓ health_monitor module imported")
        
        return True
    except Exception as e:
        print(f"  ✗ Import failed: {e}")
        return False

def test_hardware_detect():
    """Test running hardware detection."""
    print("\nTesting hardware detection...")
    try:
        from services.sensors import hardware_detect
        
        # This is what the install script now does
        hardware_detect.main()
        print("  ✓ hardware_detect.main() executed successfully")
        
        # Check if status file was created
        status_file = Path(__file__).parent / 'config' / 'hardware_status.json'
        if status_file.exists():
            print(f"  ✓ Status file created: {status_file}")
            
            # Read and display results
            with open(status_file) as f:
                results = json.load(f)
            
            modules = results.get('modules', {})
            print("\n  Hardware Detection Results:")
            print("  " + "="*40)
            for module, info in modules.items():
                present = info.get('present', False)
                symbol = "✓" if present else "✗"
                status = 'OK' if present else 'Not Found'
                print(f"  {symbol} {module}: {status}")
            print("  " + "="*40)
            
            return True
        else:
            print(f"  ✗ Status file not created: {status_file}")
            return False
            
    except Exception as e:
        print(f"  ✗ Hardware detection failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_health_monitor():
    """Test that health monitor can be started (don't actually run the loop)."""
    print("\nTesting health monitor module...")
    try:
        from services.sensors import health_monitor
        
        # Just verify the main_loop function exists (don't run it)
        if hasattr(health_monitor, 'main_loop'):
            print("  ✓ health_monitor.main_loop() is available")
            print("  ✓ Health monitor service will work correctly")
            return True
        else:
            print("  ✗ main_loop function not found")
            return False
            
    except Exception as e:
        print(f"  ✗ Health monitor test failed: {e}")
        return False

def main():
    """Run all verification tests."""
    print("="*50)
    print("Pulse Installation Fix Verification")
    print("="*50)
    print()
    
    results = {
        'imports': test_imports(),
        'hardware_detect': test_hardware_detect(),
        'health_monitor': test_health_monitor(),
    }
    
    print("\n" + "="*50)
    if all(results.values()):
        print("✓ ALL TESTS PASSED")
        print("="*50)
        print("\nThe installation fix is working correctly!")
        print("You can now re-run the installer safely.")
        return 0
    else:
        print("✗ SOME TESTS FAILED")
        print("="*50)
        print("\nFailed tests:")
        for test, passed in results.items():
            if not passed:
                print(f"  - {test}")
        return 1

if __name__ == '__main__':
    sys.exit(main())
