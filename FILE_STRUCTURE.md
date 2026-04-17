# NeuroScreen AI - File Structure Reference

## 📦 Complete Project Organization

```
NeuroScreen-AI/
│
├── 📱 neuro_app/                          # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart                      # App entry point
│   │   ├── models/
│   │   │   ├── neurology_report.dart      # Report data structure
│   │   │   ├── test_result.dart          # Test result model
│   │   │   └── user_profile.dart         # User data model
│   │   ├── screens/
│   │   │   ├── login_page.dart           # Authentication
│   │   │   ├── home_page.dart            # Dashboard
│   │   │   ├── memory_test.dart          # Memory test UI
│   │   │   ├── reaction_time_test.dart   # Reaction test UI
│   │   │   ├── motor_skills_test.dart    # Motor test UI
│   │   │   ├── eye_tracking_test.dart    # Eye tracking UI
│   │   │   ├── voice_analysis_test.dart  # Voice test UI
│   │   │   ├── neurology_report_screen.dart # Report display
│   │   │   ├── view_reports_screen.dart  # Reports list
│   │   │   └── profile_page.dart         # User profile
│   │   ├── services/
│   │   │   ├── firestore_test_service.dart    # Database
│   │   │   ├── neurological_analysis_service.dart # ML analysis
│   │   │   └── pdf_export_service.dart   # PDF generation
│   │   └── helpers/
│   │       └── test_result_helper.dart   # Utility functions
│   ├── pubspec.yaml                      # Dependencies
│   └── [iOS/Android/Web configs]
│
├── 🐍 ml_backend/                         # Python ML Backend
│   ├── main.py                           # FastAPI app
│   ├── config.py                         # Configuration management
│   ├── models.py                         # Database models
│   ├── routers/                          # API endpoints
│   │   ├── __init__.py
│   │   ├── health.py                    # Health check endpoints
│   │   ├── predictions.py               # ML predictions
│   │   ├── models.py                    # Model management
│   │   └── analytics.py                 # Analytics endpoints
│   ├── ml/                              # ML pipeline
│   │   ├── __init__.py
│   │   ├── models.py                    # Model classes
│   │   │   ├── RiskPredictor
│   │   │   ├── TrendAnalyzer
│   │   │   └── AnomalyDetector
│   │   ├── preprocessing.py             # Data preprocessing
│   │   │   ├── DataPreprocessor
│   │   │   ├── FeatureEngineer
│   │   │   └── DataValidator
│   │   └── training.py                  # Training pipeline
│   │       ├── TrainingPipeline
│   │       └── ModelEvaluator
│   ├── tests/                           # Test suite
│   │   ├── __init__.py
│   │   ├── test_models.py              # Unit tests
│   │   └── test_integration.py         # Integration tests
│   ├── init.sql                         # Database schema
│   ├── Dockerfile                       # Container image
│   ├── requirements.txt                 # Python dependencies
│   └── .env.example                     # Configuration template
│
├── 🐳 docker-compose.yml                 # Full stack orchestration
│   ├── ml_backend service
│   ├── postgresql service
│   ├── adminer service
│   ├── prometheus service
│   └── grafana service
│
├── ☸️ k8s/                               # Kubernetes manifests
│   ├── deployment.yaml                  # Deployment config
│   ├── service.yaml                     # Service config
│   └── configmap.yaml                   # Configuration
│
├── 📋 .github/
│   └── workflows/
│       └── ml-backend.yml               # CI/CD pipeline
│
├── 📚 Documentation/
│   ├── README.md                        # Main project README
│   ├── ML_BACKEND_README.md             # Backend guide
│   ├── ARCHITECTURE.md                  # System design
│   ├── API_REFERENCE.md                 # API documentation
│   ├── DEPLOYMENT_GUIDE.md              # Deployment steps
│   ├── CONTRIBUTING.md                  # Contributing guide
│   ├── FILE_STRUCTURE.md                # This file
│   ├── FINAL_STATUS_REPORT.md           # Project status
│   ├── IMPLEMENTATION_COMPLETE.md       # Implementation details
│   ├── NEUROLOGICAL_ASSESSMENT_SYSTEM.md # System details
│   └── INTEGRATION_EXAMPLES.md          # Code examples
│
├── 🔧 Configuration/
│   ├── Makefile                         # Development commands
│   ├── .gitignore                       # Git ignore rules
│   ├── .env.example                     # Environment template
│   └── pytest.ini                       # Test configuration
│
└── 📊 Analysis/
    ├── FINAL_STATUS_REPORT.md           # Project status
    ├── Project Statistics
    └── Performance Metrics
```

## 🔑 Key Files by Role

### For Mobile Developers
- `neuro_app/lib/main.dart` - App entry point
- `neuro_app/lib/screens/` - UI screens
- `neuro_app/pubspec.yaml` - Dependencies
- `neuro_app/lib/services/` - Business logic

### For ML Engineers
- `ml_backend/ml/models.py` - Model definitions
- `ml_backend/ml/preprocessing.py` - Data processing
- `ml_backend/ml/training.py` - Training pipeline
- `ml_backend/routers/predictions.py` - Inference API

### For Backend Developers
- `ml_backend/main.py` - API entry point
- `ml_backend/routers/` - Endpoints
- `ml_backend/config.py` - Configuration
- `ml_backend/models.py` - Database models

### For DevOps/Infra
- `docker-compose.yml` - Local development
- `k8s/deployment.yaml` - Kubernetes
- `Dockerfile` - Container image
- `.github/workflows/ml-backend.yml` - CI/CD

### For Project Managers
- `README.md` - Project overview
- `FINAL_STATUS_REPORT.md` - Project status
- `DEPLOYMENT_GUIDE.md` - Release process
- `ARCHITECTURE.md` - System design

## 📊 File Statistics

```
Language    Files   Lines    Notes
─────────────────────────────────
Dart        15      4,200+   Mobile app
Python      10      2,800+   ML backend
SQL         1       400+     Database schema
YAML        5       600+     Config files
Markdown    8       3,000+   Documentation
───────────────────────────────
Total       39      11,000+  Full project
```

## 🚀 Critical Files (Must Not Delete)

1. `neuro_app/lib/main.dart` - App core
2. `ml_backend/main.py` - API core
3. `docker-compose.yml` - Local setup
4. `ml_backend/ml/models.py` - ML models
5. `ml_backend/ml/preprocessing.py` - Data handling
6. `README.md` - Project documentation
7. `ARCHITECTURE.md` - Design reference
8. `.gitignore` - Version control

## 📝 Generated/Derived Files (Safe to Delete)

- `ml_backend/__pycache__/` - Python cache
- `ml_backend/.pytest_cache/` - Test cache
- `neuro_app/build/` - Build artifacts
- `neuro_app/.dart_tool/` - Dart cache
- `models/` - Trained model files (can be retrained)
- `logs/` - Log files
- `.env` - Local configuration (use .env.example)

## 🔄 File Dependencies

```
main.dart
├─ screens/*.dart (all UI)
├─ services/firestore_test_service.dart
├─ services/neurological_analysis_service.dart
└─ services/pdf_export_service.dart

main.py (FastAPI)
├─ routers/*.py (endpoints)
├─ ml/models.py (predictions)
├─ ml/preprocessing.py (data handling)
└─ config.py (settings)

docker-compose.yml
├─ Dockerfile (ML backend image)
├─ ml_backend/init.sql (database)
└─ .env (secrets)
```

## 🎯 Common Tasks & Files

### Add new API endpoint
1. Create `ml_backend/routers/new_feature.py`
2. Add route to `ml_backend/main.py`
3. Update `API_REFERENCE.md`
4. Add tests to `ml_backend/tests/`

### Add new Flutter screen
1. Create `neuro_app/lib/screens/new_screen.dart`
2. Add to navigation in `main.dart`
3. Add tests in `neuro_app/test/`

### Add new ML model
1. Create model class in `ml_backend/ml/models.py`
2. Add training code in `ml_backend/ml/training.py`
3. Add tests in `ml_backend/tests/test_models.py`
4. Create inference endpoint in `routers/predictions.py`

### Deploy changes
1. Update version in `main.py`
2. Push to git
3. GitHub Actions runs tests (`ml-backend.yml`)
4. Build Docker image
5. Deploy to cloud

---

**Last Updated**: 2024-01-15  
**Version**: 1.0.0
