# CONTRIBUTING

## Development Setup

### Prerequisites
- Python 3.11+
- Docker & Docker Compose
- Git

### Initial Setup

```bash
# Clone repository
git clone <repository>
cd NeuroScreen-AI

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
make install-dev

# Start local services
make docker-up
```

## Code Style

### Python
- Follow PEP 8
- Use type hints
- Run linter: `make lint`
- Format with Black: `make format`

```python
# Good
def predict_risk(test_results: List[TestResult]) -> Dict[str, float]:
    """Predict neurological risk from test results."""
    return {"score": 0.5, "level": "low"}

# Bad
def predict_risk(results):
    return {"score": 0.5, "level": "low"}
```

### Dart
- Follow Dart style guide
- Run `dartanalyzer`
- Format with `dart format`

## Testing

### Run All Tests
```bash
make test
```

### Write Tests
- Unit tests in `ml_backend/tests/`
- Integration tests in `ml_backend/tests/test_integration.py`
- Use pytest fixtures

```python
@pytest.fixture
def sample_data():
    return np.random.rand(100, 5)

def test_model(sample_data):
    model = RiskPredictor()
    model.train(sample_data, y)
    assert model.model is not None
```

## Commit Messages

Follow conventional commits:

```
feat: Add risk predictor model
fix: Handle missing values in preprocessing
docs: Update API reference
test: Add integration tests
refactor: Simplify trend calculation
perf: Optimize database queries
```

## Pull Request Process

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes and test: `make test`
3. Format code: `make format && make lint`
4. Commit with clear messages
5. Push and create PR
6. Ensure CI passes
7. Request review

## Versioning

Follow semantic versioning:
- **Major**: Breaking changes (1.0.0)
- **Minor**: New features (1.1.0)
- **Patch**: Bug fixes (1.1.1)

## Release Process

1. Update version in `main.py`
2. Update CHANGELOG
3. Create git tag: `git tag v1.0.0`
4. Push tag: `git push origin v1.0.0`
5. GitHub Actions will build and deploy

## Documentation

Update docs for:
- New features
- API changes
- Configuration options
- Deployment changes

## Performance Guidelines

- API response time: < 500ms
- Model inference: < 200ms
- Database query: < 100ms
- Memory usage: < 2GB per instance

## Security

- Never commit secrets
- Use environment variables
- Validate all inputs
- Sanitize SQL queries
- Update dependencies regularly

## Getting Help

- Check existing issues
- Ask in PRs
- Create issue with details
- Reference related issues

---

**Thank you for contributing!** 🎉
