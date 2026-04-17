# Quick Test Command Reference

## 🚀 Essential Commands

### Run All Tests
```bash
cd ml_backend
pytest tests/ -v
```

### Run With Coverage Report
```bash
pytest tests/ --cov=ml --cov=routers --cov-report=term-missing
```

### Run Specific Test File
```bash
pytest tests/test_models.py -v
pytest tests/test_integration.py -v
pytest tests/test_preprocessing.py -v
```

### Run Specific Test Class
```bash
pytest tests/test_models.py::TestRiskPredictor -v
pytest tests/test_integration.py::TestPredictionEndpoints -v
pytest tests/test_preprocessing.py::TestDataPreprocessor -v
```

### Run Specific Test Method
```bash
pytest tests/test_models.py::TestRiskPredictor::test_training_realistic_data -v
```

---

## 🎯 By Test Type

### Unit Tests Only (Fast)
```bash
pytest tests/ -m unit --tb=short
# ~50 tests in <2 minutes
```

### Integration Tests Only
```bash
pytest tests/ -m integration -v
# ~24 tests in <2 minutes
```

### ML Tests Only
```bash
pytest tests/ -m ml -v
# ~30 ML-specific tests
```

### API Tests Only
```bash
pytest tests/ -m api -v
# ~20 API endpoint tests
```

### Performance Tests Only
```bash
pytest tests/ -m performance -v
# Latency/throughput validation
```

### Quick Smoke Test
```bash
pytest tests/ -m "unit and not slow" -q
# <1 minute full validation
```

---

## 📊 Coverage Reports

### Terminal Coverage
```bash
pytest tests/ --cov=ml --cov=routers --cov-report=term
```

### With Missing Lines
```bash
pytest tests/ --cov=ml --cov=routers --cov-report=term-missing
```

### HTML Report
```bash
pytest tests/ --cov=ml --cov=routers --cov-report=html
open htmlcov/index.html
```

### Coverage by Module
```bash
pytest tests/ --cov=ml --cov=routers --cov-report=term:skip-covered
```

---

## 🔍 Debugging

### Show Print Statements
```bash
pytest tests/ -v -s
```

### Show Full Tracebacks
```bash
pytest tests/ -v --tb=long
```

### Stop on First Failure
```bash
pytest tests/ -x
```

### Show Slowest Tests
```bash
pytest tests/ --durations=10
```

### With Logging
```bash
pytest tests/ -v --log-cli-level=DEBUG
```

---

## ⚡ Performance Optimization

### Parallel Execution (Requires pytest-xdist)
```bash
pip install pytest-xdist
pytest tests/ -n auto
```

### Run Only Failed Tests
```bash
pytest tests/ --lf
```

### Run Failed + New Tests
```bash
pytest tests/ --ff
```

### Skip Slow Tests
```bash
pytest tests/ -m "not slow"
```

---

## 📋 Filtering

### Run by Pattern
```bash
pytest tests/ -k "risk" -v         # All tests with 'risk' in name
pytest tests/ -k "not anomaly" -v  # All except 'anomaly'
pytest tests/ -k "test_train" -v   # All training tests
```

### Run by Marker
```bash
pytest tests/ -m unit              # Unit tests
pytest tests/ -m "unit or api" -v  # Unit OR API tests
pytest tests/ -m "not slow" -q     # All fast tests
```

### Run by File Pattern
```bash
pytest tests/test_models.py tests/test_integration.py -v
```

---

## 📈 Continuous Integration

### Setup Pre-commit Hook
```bash
# Create .git/hooks/pre-commit
pytest tests/ -q || exit 1
```

### GitHub Actions (Already Configured)
```yaml
- name: Run tests
  run: pytest tests/ --cov=ml --cov-report=xml
```

### Local CI Simulation
```bash
# Lint
flake8 ml routers tests

# Type check
mypy ml routers --ignore-missing-imports

# Run tests
pytest tests/ --cov=ml --cov=routers --cov-report=term
```

---

## 🎓 Common Scenarios

### Check if Everything Works
```bash
pytest tests/ -m unit -q
```

### Full Validation Before Commit
```bash
pytest tests/ --cov=ml --cov=routers --cov-report=term && echo "✅ All good!"
```

### Test Specific Feature
```bash
pytest tests/ -k "risk_prediction" -v
```

### Find Test Failures
```bash
pytest tests/ -x --tb=short
```

### Benchmark Changes
```bash
pytest tests/ -m performance -v --durations=10
```

### Quick Health Check
```bash
pytest tests/test_integration.py::TestHealthEndpoints -v
```

---

## ✅ Expected Output

### Successful Run
```
========================= test session starts ==========================
collected 79 items

tests/test_models.py::TestRiskPredictor::test_initialization PASSED
tests/test_models.py::TestRiskPredictor::test_training_realistic_data PASSED
...
tests/test_integration.py::TestEndToEnd::test_full_workflow PASSED

========================= 79 passed in 4.23s ==========================
```

### With Coverage
```
Name                          Stmts   Miss  Cover
─────────────────────────────────────────────────
ml/models.py                    250    15    94%
ml/preprocessing.py             180    20    89%
routers/predictions.py          120    18    85%
routers/analytics.py            100     5    95%
─────────────────────────────────────────────────
TOTAL                          1200   140    88%
```

---

## 🚨 Troubleshooting

### ModuleNotFoundError
```bash
# Make sure you're in ml_backend directory
cd ml_backend
pytest tests/
```

### Import Errors
```bash
# Install all dependencies
pip install -r requirements.txt
```

### Fixture Not Found
```bash
# Make sure conftest.py is in tests/ directory
ls tests/conftest.py
```

### Tests Hanging
```bash
# Increase timeout
pytest tests/ --timeout=300
```

---

## 📚 Additional Help

### List All Tests
```bash
pytest tests/ --collect-only -q
```

### List All Markers
```bash
pytest tests/ --markers
```

### Show Fixture Details
```bash
pytest tests/ --fixtures | grep -A 5 "realistic_test_data"
```

### Run with Verbose Output
```bash
pytest tests/ -vv
```

---

## 🎯 Your Typical Workflow

```bash
# 1. Make changes to code

# 2. Quick check
pytest tests/ -m unit -q

# 3. Full validation
pytest tests/ --cov=ml --cov=routers

# 4. Check specific component
pytest tests/test_models.py -v

# 5. Before committing
pytest tests/ -m "unit and not slow" && git commit

# 6. Full suite before pushing
pytest tests/ --cov=ml --cov=routers && git push
```

---

**Quick Reference Complete!** 🚀
Save this file and bookmark it for easy reference.
