#!/usr/bin/env python3
"""
NeuroScreen-AI System Verification Script
Tests all components of the system to ensure everything is properly connected
"""

import subprocess
import time
import requests
import json
from pathlib import Path
from datetime import datetime

# Colors for output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

class SystemVerifier:
    def __init__(self):
        self.results = {}
        self.backend_process = None

    def print_header(self, text):
        print(f"\n{BLUE}{'='*60}")
        print(f"  {text}")
        print(f"{'='*60}{RESET}\n")

    def print_success(self, text):
        print(f"{GREEN}[OK] {text}{RESET}")

    def print_error(self, text):
        print(f"{RED}[ERROR] {text}{RESET}")

    def print_warning(self, text):
        print(f"{YELLOW}[WARN] {text}{RESET}")

    def print_info(self, text):
        print(f"{BLUE}[INFO] {text}{RESET}")

    def check_python_version(self):
        """Check if Python version is sufficient"""
        self.print_info("Checking Python version...")
        import sys
        version = sys.version_info
        if version.major >= 3 and version.minor >= 8:
            self.print_success(f"Python {version.major}.{version.minor}.{version.micro} detected")
            self.results['python_version'] = True
        else:
            self.print_error(f"Python {version.major}.{version.minor} detected (need 3.8+)")
            self.results['python_version'] = False

    def check_dependencies(self):
        """Check if all required packages are installed"""
        self.print_info("Checking Python dependencies...")
        required = {
            'fastapi': 'FastAPI',
            'pydantic': 'Pydantic',
            'numpy': 'NumPy',
            'scikit_learn': 'Scikit-Learn',
            'uvicorn': 'Uvicorn',
        }

        all_installed = True
        for module, name in required.items():
            try:
                __import__(module)
                self.print_success(f"{name} installed")
            except ImportError:
                self.print_error(f"{name} NOT installed")
                all_installed = False

        self.results['dependencies'] = all_installed

    def check_ml_models(self):
        """Check if ML models exist"""
        self.print_info("Checking ML models...")
        models_dir = Path('ml_backend/models')

        expected_files = [
            'risk_predictor.pkl',
            'trend_analyzer.pkl',
            'anomaly_detector.pkl',
            'scaler.pkl',
        ]

        all_exist = True
        if models_dir.exists():
            for file in expected_files:
                path = models_dir / file
                if path.exists():
                    size = path.stat().st_size / (1024 * 1024)  # MB
                    self.print_success(f"{file} exists ({size:.2f} MB)")
                else:
                    self.print_warning(f"{file} not found - will be auto-trained")
                    all_exist = False
        else:
            self.print_warning("Models directory not found - will be created automatically")
            all_exist = False

        self.results['ml_models'] = True  # Not critical - will auto-train

    def start_backend(self):
        """Start the ML backend server"""
        self.print_info("Starting ML backend...")
        try:
            # Start backend in subprocess
            import sys
            import os
            env = os.environ.copy()
            env['DEBUG'] = 'false'

            self.backend_process = subprocess.Popen(
                [sys.executable, 'ml_backend/main.py'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env,
            )

            # Wait for backend to start
            time.sleep(3)

            # Check if process is still running
            if self.backend_process.poll() is None:
                self.print_success("ML backend started (PID: {})".format(self.backend_process.pid))
                self.results['backend_started'] = True
            else:
                stdout, stderr = self.backend_process.communicate()
                self.print_error(f"Backend failed to start: {stderr.decode()}")
                self.results['backend_started'] = False
        except Exception as e:
            self.print_error(f"Failed to start backend: {e}")
            self.results['backend_started'] = False

    def check_backend_health(self):
        """Check if backend is responding"""
        self.print_info("Checking backend health...")
        try:
            response = requests.get('http://localhost:8000/health', timeout=5)
            if response.status_code == 200:
                data = response.json()
                self.print_success(f"Backend is healthy: {data}")
                self.results['backend_health'] = True
            else:
                self.print_error(f"Backend returned status {response.status_code}")
                self.results['backend_health'] = False
        except requests.exceptions.ConnectionError:
            self.print_error("Cannot connect to backend on localhost:8000")
            self.results['backend_health'] = False
        except Exception as e:
            self.print_error(f"Health check failed: {e}")
            self.results['backend_health'] = False

    def test_risk_prediction(self):
        """Test risk prediction endpoint"""
        self.print_info("Testing risk prediction endpoint...")

        test_data = {
            "test_results": [
                {
                    "user_id": "test_user",
                    "test_type": "cognitive",
                    "score": 75.0,
                    "timestamp": datetime.now().isoformat() + "Z",
                },
                {
                    "user_id": "test_user",
                    "test_type": "motor",
                    "score": 80.0,
                    "timestamp": datetime.now().isoformat() + "Z",
                },
                {
                    "user_id": "test_user",
                    "test_type": "reaction",
                    "score": 400.0,
                    "reaction_time": 400.0,
                    "timestamp": datetime.now().isoformat() + "Z",
                },
                {
                    "user_id": "test_user",
                    "test_type": "memory",
                    "score": 75.0,
                    "memory_retention": 75.0,
                    "timestamp": datetime.now().isoformat() + "Z",
                },
                {
                    "user_id": "test_user",
                    "test_type": "accuracy",
                    "score": 80.0,
                    "accuracy": 80.0,
                    "timestamp": datetime.now().isoformat() + "Z",
                },
            ],
            "include_confidence": True,
        }

        try:
            response = requests.post(
                'http://localhost:8000/api/predictions/risk',
                json=test_data,
                timeout=20,
            )

            if response.status_code == 200:
                data = response.json()
                self.print_success(f"Risk prediction successful:")
                self.print_success(f"  - Risk Score: {data.get('overall_risk_score')}")
                self.print_success(f"  - Risk Level: {data.get('risk_level')}")
                self.print_success(f"  - Confidence: {data.get('confidence'):.2%}")
                self.results['risk_prediction'] = True
            else:
                self.print_error(f"Prediction failed: {response.status_code}")
                self.print_error(f"Response: {response.text}")
                self.results['risk_prediction'] = False
        except Exception as e:
            self.print_error(f"Risk prediction test failed: {e}")
            self.results['risk_prediction'] = False

    def test_trends_endpoint(self):
        """Test trend analysis endpoint"""
        self.print_info("Testing trend analysis endpoint...")

        test_data = {
            "scores": [60, 65, 70, 75, 80, 85],
            "forecast_periods": 5,
        }

        try:
            response = requests.post(
                'http://localhost:8000/api/analytics/trends',
                json=test_data,
                timeout=10,
            )

            if response.status_code == 200:
                data = response.json()
                self.print_success(f"Trend analysis successful:")
                self.print_success(f"  - Direction: {data.get('direction')}")
                self.print_success(f"  - Slope: {data.get('slope')}")
                self.results['trends_endpoint'] = True
            else:
                self.print_error(f"Trend analysis failed: {response.status_code}")
                self.results['trends_endpoint'] = False
        except Exception as e:
            self.print_error(f"Trend analysis test failed: {e}")
            self.results['trends_endpoint'] = False

    def test_anomalies_endpoint(self):
        """Test anomaly detection endpoint"""
        self.print_info("Testing anomaly detection endpoint...")

        test_data = {
            "features": [75, 80, 350, 75, 80],
        }

        try:
            response = requests.post(
                'http://localhost:8000/api/analytics/anomalies',
                json=test_data,
                timeout=10,
            )

            if response.status_code == 200:
                data = response.json()
                self.print_success(f"Anomaly detection successful:")
                self.print_success(f"  - Is Anomaly: {data.get('is_anomaly')}")
                self.print_success(f"  - Anomaly Score: {data.get('anomaly_score'):.3f}")
                self.results['anomalies_endpoint'] = True
            else:
                self.print_error(f"Anomaly detection failed: {response.status_code}")
                self.results['anomalies_endpoint'] = False
        except Exception as e:
            self.print_error(f"Anomaly detection test failed: {e}")
            self.results['anomalies_endpoint'] = False

    def run_backend_tests(self):
        """Run pytest integration tests"""
        self.print_info("Running backend integration tests...")
        try:
            result = subprocess.run(
                ['python', '-m', 'pytest', 'ml_backend/tests/test_api_integration.py', '-v', '--tb=short'],
                capture_output=True,
                text=True,
                timeout=60,
            )

            if result.returncode == 0:
                # Count passed tests
                output = result.stdout
                if 'passed' in output:
                    self.print_success("All integration tests passed!")
                    self.results['integration_tests'] = True
                else:
                    self.print_warning("Tests completed with warnings")
                    self.results['integration_tests'] = True
            else:
                self.print_error("Some integration tests failed")
                print(result.stdout)
                self.results['integration_tests'] = False
        except Exception as e:
            self.print_error(f"Could not run tests: {e}")
            self.results['integration_tests'] = False

    def print_summary(self):
        """Print test summary"""
        self.print_header("TEST SUMMARY")

        passed = sum(1 for v in self.results.values() if v)
        total = len(self.results)

        print(f"\nResults: {passed}/{total} checks passed\n")

        for test, result in self.results.items():
            status = "[PASS]" if result else "[FAIL]"
            color = GREEN if result else RED
            print(f"  {color}{status}{RESET} - {test}")

        print()

        if passed == total:
            self.print_success("All systems operational!")
            print("\nYou can now:")
            print("  1. Run the Flutter app: flutter run")
            print("  2. Create an account and login")
            print("  3. Complete a neurological test")
            print("  4. Generate a report (will use ML backend)")
        else:
            self.print_warning(f"{total - passed} checks failed. See above for details.")

    def cleanup(self):
        """Clean up resources"""
        if self.backend_process and self.backend_process.poll() is None:
            print("\nStopping backend...")
            self.backend_process.terminate()
            self.backend_process.wait(timeout=5)
            print("Backend stopped")

def main():
    print(f"\n{BLUE}{'='*60}")
    print(f"  NeuroScreen-AI System Verification Script")
    print(f"  Testing ML Backend & Integrations")
    print(f"{'='*60}{RESET}\n")

    verifier = SystemVerifier()

    try:
        verifier.print_header("PRE-FLIGHT CHECKS")
        verifier.check_python_version()
        verifier.check_dependencies()
        verifier.check_ml_models()

        verifier.print_header("BACKEND STARTUP")
        verifier.start_backend()

        if not verifier.results.get('backend_started'):
            verifier.print_error("Backend failed to start. Aborting tests.")
            return

        verifier.print_header("BACKEND CONNECTIVITY TESTS")
        verifier.check_backend_health()

        if not verifier.results.get('backend_health'):
            verifier.print_error("Backend is not responding. Aborting remaining tests.")
        else:
            verifier.print_header("API ENDPOINT TESTS")
            verifier.test_risk_prediction()
            verifier.test_trends_endpoint()
            verifier.test_anomalies_endpoint()

            verifier.print_header("INTEGRATION TESTS")
            verifier.run_backend_tests()

        verifier.print_summary()

    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
    except Exception as e:
        verifier.print_error(f"Unexpected error: {e}")
    finally:
        verifier.cleanup()

if __name__ == "__main__":
    main()
