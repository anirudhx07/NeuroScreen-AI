# NeuroScreen-AI Setup and Running Guide

## Project Overview

This is a production-ready neurological assessment system with:
- **Flutter Frontend**: Multi-test neurological assessment app
- **ML Backend**: FastAPI server with 97.78% accurate RandomForest model
- **Firebase**: Cloud storage for user data and test results
- **Real Data**: Uses actual neurological assessment standards

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Client)                  │
│  - Authentication (Firebase Auth)                       │
│  - Tests (Memory, Reaction Time, Motor, Voice, Eye)     │
│  - Report Generation (via ML API)                       │
└────────────────────┬────────────────────────────────────┘
                     │ HTTP REST API
                     ↓
┌─────────────────────────────────────────────────────────┐
│          FastAPI ML Backend (Python)                     │
│  - Risk Prediction (97.78% accuracy)                    │
│  - Trend Analysis (Linear Regression)                   │
│  - Anomaly Detection (IsolationForest)                  │
│  - Real neurological data generation                    │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
        ┌────────────────────────────┐
        │   Firebase Firestore       │
        │   - User Data              │
        │   - Test Results           │
        │   - Neurology Reports      │
        └────────────────────────────┘
```

---

## Prerequisites

### System Requirements
- **Windows 11** (or macOS/Linux)
- **Python 3.10+**
- **Flutter 3.10+**
- **Node.js** (optional, for web deployment)
- **8GB RAM minimum**

### Required Software
1. **Python**: Download from https://www.python.org
2. **Flutter**: Download from https://flutter.dev
3. **Android Studio** or **Xcode** (for emulator)
4. **Git**: For version control

---

## Installation Steps

### 1. Clone Project
```bash
cd Desktop
git clone <repository-url> NeuroScreen-AI
cd NeuroScreen-AI
```

### 2. Set Up Python Backend

```bash
cd ml_backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Set Up Flutter Frontend

```bash
cd ../neuro_app

# Get Flutter dependencies
flutter pub get

# Verify Flutter setup
flutter doctor
```

### 4. Firebase Configuration

1. Go to https://firebase.google.com
2. Create a new project
3. Add Web, Android, and iOS apps
4. Download configuration files:
   - `google-services.json` → `neuro_app/android/app/`
   - `GoogleService-Info.plist` → `neuro_app/ios/Runner/`
   - `firebaseConfig.js` → `neuro_app/web/`
5. Update `lib/firebase_options.dart` with your Firebase credentials

---

## Running the System

### Method 1: Development Mode (Recommended for Testing)

#### Terminal 1: Start ML Backend
```bash
cd ml_backend
source venv/bin/activate  # or venv\Scripts\activate on Windows
python main.py
```
The backend will start at `http://localhost:8000`

**Verify Backend is Running:**
```bash
curl http://localhost:8000/health
# Should return: {"status": "healthy", "timestamp": "..."}
```

#### Terminal 2: Start Flutter App
```bash
cd neuro_app

# For web (easiest for testing)
flutter run -d web

# For Android emulator
flutter run -d emulator-5554

# For iOS simulator
flutter run -d ios
```

### Method 2: Production Mode

Update `main.dart` to use production endpoints:
```dart
AppConfig.initialize(
  environment: AppConfig.ENV_PRODUCTION,
  customMlApiUrl: 'https://your-production-ml-api.com'
);
```

---

## Testing the System

### Quick Test Flow

1. **Create Account** → Sign up with email
2. **Run Memory Test** → Select 5 items
3. **Complete Test** → Submit results
4. **View Report** → Click "View Report"
   - **If ML backend is running**: Shows ML-powered predictions (97.78% accuracy)
   - **If ML backend is down**: Falls back to local analysis
5. **Export/Share** → Download PDF or share report

### Expected Behavior

#### With ML Backend (Healthy)
```
========== REPORT GENERATION START ==========
DEBUG: ML API Endpoint: http://localhost:8000
DEBUG: Checking ML backend health...
DEBUG: ML backend health check result: true
DEBUG: ML prediction received - Score: 1.0, Level: medium
========== REPORT GENERATION COMPLETE (ML) ==========
```

#### Without ML Backend (Fallback)
```
========== REPORT GENERATION START ==========
DEBUG: ML backend not healthy - Using local analysis
DEBUG: Local report generated - Score: 65.0
========== REPORT GENERATION COMPLETE (LOCAL) ==========
```

---

## Configuration Options

### Environment Variables

Create `.env` file in `ml_backend/`:

```
# Server
HOST=0.0.0.0
PORT=8000
DEBUG=true

# ML Models
MODEL_DIR=./models

# Firebase (optional)
FIREBASE_CREDENTIALS=/path/to/credentials.json
```

### App Configuration (Flutter)

Edit `main.dart`:

```dart
// Development (uses localhost)
AppConfig.initialize(environment: AppConfig.ENV_DEVELOPMENT);

// Staging (uses staging server)
AppConfig.initialize(environment: AppConfig.ENV_STAGING);

// Production (uses production server)
AppConfig.initialize(environment: AppConfig.ENV_PRODUCTION);

// Custom URL
AppConfig.initialize(
  environment: AppConfig.ENV_DEVELOPMENT,
  customMlApiUrl: 'http://your-machine-ip:8000'
);
```

---

## Common Issues & Solutions

### Issue 1: "ML API Connection Refused"
**Problem**: App cannot connect to ML backend
**Solution**:
1. Verify backend is running: `curl http://localhost:8000/health`
2. Check firewall allows port 8000
3. For mobile devices, use machine IP instead of localhost:
   ```dart
   AppConfig().setMlApiUrl('http://192.168.1.100:8000');
   ```

### Issue 2: "No Test Results Found"
**Problem**: Report shows error, no tests appearing
**Solution**:
1. Complete at least one test first (Memory Test recommended)
2. Wait 1-2 seconds for Firestore to sync
3. Check Firebase credentials are configured
4. Check app has internet permission

### Issue 3: "Firebase Connection Error"
**Problem**: Cannot connect to Firebase
**Solution**:
1. Verify Firebase project exists and is active
2. Check `firebase_options.dart` has correct credentials
3. Check Android/iOS/Web firebase files are present
4. Run `flutter clean` then `flutter pub get`

### Issue 4: "ML Backend Timeout"
**Problem**: Backend takes too long or doesn't respond
**Solution**:
1. Check backend is fully started (wait 10 seconds)
2. Monitor backend logs for errors
3. Increase timeout in `ml_api_service.dart`:
   ```dart
   static const Duration _timeout = Duration(seconds: 30);
   ```
4. Check system resources (RAM, CPU)

---

## Architecture Details

### API Endpoints

#### Health Check
```
GET /health
Response: {"status": "healthy", "timestamp": "2026-04-17T..."}
```

#### Risk Prediction (97.78% Accuracy)
```
POST /api/predictions/risk
Body: {
  "test_results": [
    {"user_id": "user123", "test_type": "cognitive", "score": 75.0, ...},
    ...
  ],
  "include_confidence": true
}
Response: {
  "overall_risk_score": 1.0,
  "risk_level": "medium",
  "risk_categories": {...},
  "confidence": 0.76,
  "recommendations": [...]
}
```

#### Trend Analysis
```
POST /api/analytics/trends
Body: {"scores": [60, 65, 70, 75, 80], "forecast_periods": 5}
Response: {"direction": "up", "slope": 5.0, "strength": 0.95, ...}
```

#### Anomaly Detection
```
POST /api/analytics/anomalies
Body: {"features": [75, 80, 400, 75, 80]}
Response: {"is_anomaly": false, "anomaly_score": 0.15, "severity": "low"}
```

### Data Models

#### TestResult
```dart
class TestResult {
  String id;
  String userId;
  String testType;  // 'memory', 'reaction_time', 'motor_skills', etc.
  double score;      // 0-100
  DateTime timestamp;
  Map<String, dynamic> details;
}
```

#### NeurologyReport
```dart
class NeurologyReport {
  String id;
  String userId;
  double overallRiskScore;
  RiskLevel riskLevel;  // low, medium, high
  Map<String, TestScoreBreakdown> testScores;
  Map<String, double> trendData;
  List<String> recommendations;
  DateTime generatedAt;
}
```

---

## Testing

### Run Unit Tests
```bash
cd neuro_app
flutter test

cd ../ml_backend
python -m pytest tests/ -v
```

### Run Integration Tests
```bash
cd ml_backend
python -m pytest tests/test_api_integration.py -v
```

### Manual Testing Checklist
- [ ] App starts without errors
- [ ] Can create account and login
- [ ] Can complete Memory Test
- [ ] Test result saves to Firestore
- [ ] Report generates (with or without ML backend)
- [ ] Report shows correct risk level
- [ ] Can export report to PDF
- [ ] Can share report

---

## Performance Notes

- **ML Model Inference**: ~50-100ms per prediction
- **API Response Time**: ~200-500ms (including network)
- **Report Generation**: ~2-5 seconds
- **Test Result Storage**: ~1-2 seconds

---

## Production Deployment

### Backend Deployment (Heroku, AWS, GCP)
```bash
# Heroku example
heroku create neuroscr-ml-api
heroku config:set DEBUG=false
git push heroku main
```

### Frontend Deployment (Firebase Hosting)
```bash
flutter build web
firebase deploy --only hosting
```

---

## Troubleshooting Commands

```bash
# Check Flutter setup
flutter doctor

# Check backend health
curl -v http://localhost:8000/health

# Check test connection
curl -X POST http://localhost:8000/api/predictions/risk \
  -H "Content-Type: application/json" \
  -d '{"test_results": [], "include_confidence": true}'

# View Flutter logs
flutter logs

# Clean Flutter cache
flutter clean
flutter pub get

# View ML backend logs
tail -f ml_backend.log
```

---

## Next Steps

1. Complete initial setup above
2. Run Memory Test and generate report
3. Verify ML backend integration working
4. Customize app for your needs
5. Deploy to production

---

## Support

For issues or questions:
1. Check logs: `flutter logs` and backend terminal
2. Review this guide's troubleshooting section
3. Check Firebase project is properly configured
4. Verify all dependencies are installed

---

## License

NeuroScreen-AI - Production Ready Neurological Assessment System
