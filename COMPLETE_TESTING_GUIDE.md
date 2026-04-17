# COMPLETE TESTING & TROUBLESHOOTING GUIDE

## STEP-BY-STEP TEST PROCEDURE

### PHASE 1: Backend Verification (5 minutes)

#### Step 1.1: Start Backend
```bash
cd ml_backend
python main.py
```

**Expected Output:**
```
Starting NeuroScreen ML Backend v1.0.0
Server running at http://0.0.0.0:8000
```

**Troubleshooting:**
- If error: Check Python is installed: `python --version`
- If port error: Port 8000 in use. Change in `ml_backend/config.py` or kill process using port

#### Step 1.2: Test Health Endpoint (in new terminal)
```bash
curl http://localhost:8000/health
```

**Expected Output:**
```json
{"status":"healthy","timestamp":"2026-04-17T..."}
```

**If fails:**
- Backend not running? Check terminal 1
- Firewall blocking port 8000? Check Windows Defender
- Try: `netstat -ano | findstr :8000` to see what's using the port

#### Step 1.3: Test Risk Prediction
```bash
curl -X POST http://localhost:8000/api/predictions/risk \
  -H "Content-Type: application/json" \
  -d '{"test_results":[{"user_id":"test","test_type":"cognitive","score":75.0,"timestamp":"2026-04-17T10:00:00Z"}],"include_confidence":true}'
```

**Expected Output:**
```json
{"overall_risk_score":...,"risk_level":"medium",...}
```

**If fails:**
- Port issue? See Step 1.2
- Model loading issue? Check `ml_backend/ml/models.py`
- Check terminal 1 for error messages

---

### PHASE 2: Flutter App Launch (5 minutes)

#### Step 2.1: Start Flutter App
```bash
cd neuro_app
flutter run -d web
```

**Expected:**
- App opens in browser at `http://localhost:52682` (port may vary)
- See login/signup screen
- No errors in terminal

**If app doesn't open:**
- Error in terminal? Read the error message
- If compilation error: Run `flutter clean && flutter pub get`
- If device not found: Run `flutter devices`

#### Step 2.2: Check Console Logs
- Open DevTools (F12 in browser)
- Go to Console tab
- Look for any red error messages

**Common issues:**
- Firebase initialization error → Check firebase_options.dart
- ML API connection error → Check if backend is running
- Firestore error → Check Firebase credentials

---

### PHASE 3: Test Execution (10 minutes)

#### Step 3.1: Create Account
1. Click "Sign Up"
2. Enter email: `test@test.com`
3. Enter password: `Test123456`
4. Click "Sign Up"

**Expected:**
- Firebase authenticates (may take 2-3 seconds)
- Redirected to home page

**If fails:**
- Firebase error in console? Check firebase_options.dart
- "Email already in use"? Create new email

#### Step 3.2: Run Any Test
1. From home page, click any test (e.g., "Reaction Time")
2. Complete the test
3. Click "Complete"

**What should happen:**
```
1. Test executes
2. Results displayed
3. Click "Complete" button
4. _storeTestResult() called
5. Data sent to Firestore
6. Return to home
```

**Check console for:**
```
Reaction time test result stored: XXX ms
```

**If you DON'T see this message:**
- The _storeTestResult() method didn't execute
- Check reaction_time_test.dart has storage code
- Check button calls _storeTestResult()

#### Step 3.3: View Report
1. From home page, click "View Report" (or navigate after test)
2. Report screen should load

**What should happen:**
```
Report Generation:
1. Load tests from Firestore
2. Check ML backend health
3. Call ML API
4. Generate report
5. Display results
```

**Check console for:**
```
========== REPORT GENERATION START ==========
DEBUG: Found X recent test results
DEBUG: ML backend health check result: true
DEBUG: ML prediction received - Score: X.X, Level: medium
========== REPORT GENERATION COMPLETE (ML) ==========
```

**If you see:**
```
========== REPORT GENERATION START ==========
DEBUG: Found 0 recent test results
========== REPORT GENERATION FAILED ==========
```

Then: **Test results not being stored!** See troubleshooting below.

---

## TROUBLESHOOTING DECISION TREE

### Issue: "No test results found" in Report

**Root Cause Checklist:**
1. ❓ Did you complete a test?
   - No → Complete a test first
   
2. ❓ Did console show "test result stored"?
   - No → Check test screen has _storeTestResult() method
   - No → Check Complete button calls _storeTestResult()
   - No → Check imports in test file
   
3. ❓ Is Firebase working?
   - Check: Open DevTools Console
   - Look for Firebase errors
   - If errors: Check firebase_options.dart credentials
   
4. ❓ Is Firestore accessible?
   - Manual check: Try logging in (tests authentication)
   - If login fails: Firebase issue
   - If login works: Check Firestore rules

**Fix:**
```
a) Verify test screen has:
   - import 'package:neuro_app/helpers/test_result_helper.dart';
   - Future<void> _storeTestResult() async {...}
   - _storeTestResult(); in Complete button

b) Check imports are correct:
   - firebase_auth
   - test_result_helper
   - neurology_report_screen

c) Verify Firestore rules allow writes:
   - Go to Firebase Console
   - Firestore Database → Rules
   - Should allow authenticated users to read/write
```

---

### Issue: "ML backend is not healthy"

**This means:**
- Health check to `/health` endpoint failed
- ML backend not responding

**Steps:**
1. Is backend running?
   - Terminal 1: Check if `python main.py` is still running
   - If not: Start it again
   - If error: Check terminal for error message

2. Is it on the right port?
   - Default: `http://localhost:8000`
   - Check: `curl http://localhost:8000/health`
   - If fails: Port issue or backend crashed

3. Is there a firewall?
   - Windows Defender/Antivirus blocking port 8000?
   - Try: `netstat -ano | findstr :8000`
   - Kill and restart backend

**Fix:**
```bash
# In Terminal 1:
Ctrl+C (kill backend)
python main.py  (restart)

# In Terminal 3 (verify):
curl http://localhost:8000/health
# Should return: {"status":"healthy"...}
```

---

### Issue: ML Endpoint Timeout or Error

**Symptoms:**
```
ERROR: ML API failed (Connection timeout), falling back
```

**Causes:**
1. ML backend not running → See above
2. ML backend crashed → Check terminal 1
3. Model training taking too long → Wait 30+ seconds
4. Network issue → Check localhost reachability

**Verify:**
```bash
# Terminal 3:
curl -v http://localhost:8000/health
# Should show: HTTP/1.1 200 OK
```

---

### Issue: Firebase Authentication Not Working

**Symptoms:**
- Can't sign up
- Can't log in
- Error in console about Firebase

**Steps:**
1. Check firebase_options.dart exists and has credentials
2. Check Firebase project is active
3. Check Authentication is enabled in Firebase Console
4. Verify Email/Password auth is enabled

**Fix:**
```dart
// neuro_app/lib/firebase_options.dart should have:
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: '1:YOUR_APP_ID:web:...',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.firebasestorage.app',
  authDomain: 'your-project-id.firebaseapp.com',
);
```

---

## COMPLETE DATA FLOW VERIFICATION

### What SHOULD happen (step by step):

```
1. USER COMPLETES TEST
   ↓ Screen shows results
   
2. USER CLICKS "COMPLETE"
   ↓ _storeTestResult() called
   ↓ TestResultHelper.storeXxxTestResult() called
   ↓ Console: "test result stored: XXX"
   
3. TEST RESULT STORED TO FIRESTORE
   ↓ User returns to home
   ↓ Firebase: Collection 'users/{userId}/test_results' has new document
   
4. USER NAVIGATES TO "VIEW REPORT"
   ↓ NeurologyReportScreen created
   ↓ _loadAndGenerateReport() called
   ↓ Console: "========== REPORT GENERATION START =========="
   
5. QUERY FIRESTORE FOR TEST RESULTS
   ↓ Firebase: Query getRecentTestResults(userId, days=30)
   ↓ Console: "Found X recent test results"
   
6. CHECK ML BACKEND HEALTH
   ↓ HTTP GET /health
   ↓ Console: "ML backend health check result: true"
   
7. CALL ML API FOR PREDICTIONS
   ↓ HTTP POST /api/predictions/risk with test data
   ↓ ML: Runs RandomForest classifier
   ↓ Console: "ML prediction received - Score: X.X, Level: medium"
   
8. CREATE REPORT FROM ML PREDICTIONS
   ↓ NeurologyReport object created
   ↓ Store to Firestore
   ↓ Console: "Report created from ML backend"
   
9. DISPLAY REPORT
   ↓ UI updated with risk score, level, recommendations
   ↓ Console: "========== REPORT GENERATION COMPLETE (ML) =========="
   
10. USER SEES COMPREHENSIVE ASSESSMENT
    ↓ Risk level: Low/Medium/High
    ↓ Recommendations based on ML analysis
    ↓ Trend data and visualizations
```

---

## CONSOLE OUTPUT CHECKLIST

### For test result storage, you should see:
```
✓ Reaction time test result stored: XXX ms
  OR
✓ Motor skills test result stored: XXX taps
  OR  
✓ Voice analysis test result stored: XXX seconds
  OR
✓ Eye tracking test result stored: Accuracy XX%
  OR
✓ Memory test result stored: X/5 correct
```

### For report generation, you should see:
```
✓ ========== REPORT GENERATION START ==========
✓ DEBUG: ML API Endpoint: http://localhost:8000
✓ DEBUG: Checking ML backend health...
✓ DEBUG: ML backend health check result: true
✓ DEBUG: Found X recent test results
✓ DEBUG: Calling ML backend API for risk prediction
✓ DEBUG: ML prediction received - Score: X.X, Level: medium
✓ DEBUG: Report created from ML backend
✓ ========== REPORT GENERATION COMPLETE (ML) ==========
```

---

## QUICK DIAGNOSTIC COMMANDS

Run these in separate terminals:

**Terminal 1: Backend**
```bash
cd ml_backend
python main.py
```

**Terminal 2: App**
```bash
cd neuro_app
flutter run -d web
```

**Terminal 3: Tests**
```bash
# Test backend health
curl http://localhost:8000/health

# Test risk prediction
curl -X POST http://localhost:8000/api/predictions/risk \
  -H "Content-Type: application/json" \
  -d '{"test_results":[{"user_id":"test","test_type":"cognitive","score":75,"timestamp":"2026-04-17T10:00:00Z"}]}'

# Run verification script
python verify_system.py
```

---

## IF NOTHING WORKS

### Try this nuclear option:

```bash
# 1. Kill everything
# Close all terminals and browser

# 2. Fresh start
cd /c/Users/LENOVO/Desktop/NeuroScreen-AI

# 3. Backend
cd ml_backend
python -m pip install -r requirements.txt
python main.py
# Wait 10 seconds, verify: curl http://localhost:8000/health

# 4. App (NEW TERMINAL)
cd /c/Users/LENOVO/Desktop/NeuroScreen-AI/neuro_app
flutter clean
flutter pub get  
flutter run -d web

# 5. Test (NEW TERMINAL)
# Go through complete test sequence in app
```

---

## WHAT YOU'RE LOOKING FOR

✓ App starts without crashing  
✓ Can sign up and log in  
✓ Can complete any test  
✓ Console shows "test result stored: XXX"  
✓ Can view report  
✓ Console shows ML predictions  
✓ Report displays risk level and recommendations  

**If you see all of these, the system is working!**

---

If you still have issues after following this guide, provide:
1. Exact error message from console
2. Screenshot of console output
3. What step fails?
4. Which terminal shows the error?
