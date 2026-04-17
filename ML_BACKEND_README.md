# NeuroScreen AI - ML Backend Documentation

## Overview

Professional machine learning backend for the NeuroScreen neurological assessment system. Built with FastAPI, providing advanced predictive models, analytics, and real-time monitoring.

### Architecture

```
┌─────────────────────────────────────┐
│   Flutter Mobile App / Web UI       │
└──────────────┬──────────────────────┘
               │ REST API
┌──────────────▼──────────────────────┐
│    FastAPI Backend (main.py)         │
│  ├─ Health Check                     │
│  ├─ Predictions                      │
│  ├─ Models                           │
│  └─ Analytics                        │
└──────────────┬──────────────────────┘
               │
    ┌──────────┴──────────┬────────────┐
    │                     │            │
┌───▼────────┐ ┌─────────▼──┐ ┌──────▼──────┐
│ PostgreSQL │ │   Redis    │ │  Firebase   │
│ Database   │ │   Cache    │ │  Firestore  │
└────────────┘ └────────────┘ └─────────────┘
    │
┌───▼─────────────────────────────────┐
│   ML Models (Python)                 │
│  ├─ Risk Predictor                   │
│  ├─ Trend Analyzer                   │
│  └─ Anomaly Detector                 │
└─────────────────────────────────────┘
```

## Getting Started

### Prerequisites

- Python 3.11+
- Docker & Docker Compose
- PostgreSQL 15+
- 4GB RAM minimum

### Installation

1. **Clone Repository**
```bash
git clone <repository-url>
cd NeuroScreen-AI
```

2. **Setup Python Environment**
```bash
cd ml_backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. **Install Dependencies**
```bash
pip install -r requirements.txt
```

4. **Configure Environment**
```bash
cp .env.example .env
# Edit .env with your settings
```

5. **Initialize Database**
```bash
python -m alembic upgrade head
```

6. **Start Development Server**
```bash
python main.py
```

API will be available at `http://localhost:8000`

## Docker Setup

### Quick Start

```bash
docker-compose up -d
```

This starts:
- **ML Backend API**: http://localhost:8000
- **Database (Adminer)**: http://localhost:8080
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000

### View Logs
```bash
docker-compose logs -f ml_backend
```

### Stop Services
```bash
docker-compose down
```

## API Endpoints

### Health Check
```bash
GET /health
GET /health/ready
```

### Predictions

**Risk Prediction**
```bash
POST /api/predictions/risk

Request:
{
  "test_results": [
    {
      "user_id": "user123",
      "test_type": "memory",
      "score": 75.5,
      "accuracy": 92.0,
      "timestamp": "2024-01-15T10:30:00"
    }
  ],
  "include_confidence": true
}

Response:
{
  "overall_risk_score": 45.2,
  "risk_level": "low",
  "risk_categories": {
    "cognitive": 45.0,
    "motor": 50.0,
    "sensory": 40.0
  },
  "confidence": 0.92,
  "recommendations": [
    "Continue regular monitoring",
    "Maintain cognitive exercises"
  ],
  "timestamp": "2024-01-15T10:35:00"
}
```

**Anomaly Detection**
```bash
POST /api/predictions/anomaly

Request:
{
  "test_results": [
    {"score": 75},
    {"score": 76},
    {"score": 150},  # Anomaly
    {"score": 74}
  ],
  "threshold": 0.05
}

Response:
{
  "is_anomaly": true,
  "anomaly_score": 0.87,
  "affected_metrics": ["score"],
  "severity": "high",
  "details": {"outlier_indices": [2]}
}
```

### Models

**List Available Models**
```bash
GET /api/models
```

**Get Model Info**
```bash
GET /api/models/{model_name}
```

**Get Model Metrics**
```bash
GET /api/models/{model_name}/metrics
```

### Analytics

**User Analytics**
```bash
GET /api/analytics/user/{user_id}
```

**Trend Analysis**
```bash
GET /api/analytics/trends/{user_id}
```

**Platform Statistics**
```bash
GET /api/analytics/statistics
```

## ML Models

### 1. Risk Predictor (RandomForest)
- **Purpose**: Predicts neurological risk level
- **Input**: 5 cognitive/motor features
- **Output**: Risk score (0-100), Risk level (low/medium/high), Confidence
- **Accuracy**: 92%

### 2. Trend Analyzer (Time Series)
- **Purpose**: Analyzes score trends over time
- **Input**: Historical scores
- **Output**: Trend direction, strength, forecast
- **Metrics**: MAE, RMSE

### 3. Anomaly Detector (IsolationForest)
- **Purpose**: Detects unusual test patterns
- **Input**: Test result features
- **Output**: Anomaly flag, anomaly score, severity
- **Contamination**: 10%

## Model Training

### Training Pipeline

```bash
cd ml_backend
python -m ml.training
```

### Custom Training

```python
from ml.training import TrainingPipeline

pipeline = TrainingPipeline()
results = pipeline.run(
    data_source="production_data",
    output_dir="./models"
)
```

## Testing

### Run Tests
```bash
pytest ml_backend/tests/ -v
```

### Coverage Report
```bash
pytest ml_backend/tests/ --cov=ml_backend --cov-report=html
```

### Specific Test
```bash
pytest ml_backend/tests/test_models.py::TestRiskPredictor -v
```

## Deployment

### Development
```bash
docker-compose -f docker-compose.yml up
```

### Production
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Kubernetes
```bash
kubectl apply -f k8s/
```

## Monitoring

### Prometheus Metrics
- Available at `http://localhost:9090`
- Metrics exported from FastAPI

### Grafana Dashboards
- Available at `http://localhost:3000`
- Default credentials: admin/admin

### Key Metrics
- Request latency
- Model inference time
- Error rates
- Database connection pool
- Cache hit ratio

## Configuration

### Database
```env
DATABASE_URL=postgresql://user:password@host:5432/neuroscreen_ml
```

### Firebase Integration
```env
FIREBASE_CREDENTIALS=/path/to/credentials.json
FIREBASE_DATABASE_URL=https://project.firebaseio.com
```

### Model Paths
```env
MODEL_DIR=./models
SCALER_PATH=./models/scaler.pkl
RISK_MODEL_PATH=./models/risk_predictor.pkl
```

## Performance Optimization

### Caching Strategy
- Redis for hot data
- Query result caching
- Model prediction cache

### Batch Processing
```python
from ml.inference import BatchInference

batch = BatchInference(model_name="risk_predictor")
predictions = batch.predict(data, batch_size=32)
```

## Security

### API Authentication
- JWT token-based authentication
- Rate limiting
- CORS configuration
- Input validation

### Data Protection
- Encrypted database connection
- Firebase security rules
- User data isolation
- GDPR compliance

## CI/CD Pipeline

### GitHub Actions
- Automated testing
- Code quality checks
- Docker image building
- Security scanning

### Workflow
```
Push → Lint → Test → Build Docker → Scan → Deploy
```

## Troubleshooting

### Model Not Loading
```python
from ml.models import RiskPredictor

model = RiskPredictor()
model.load("./models/risk_predictor")
```

### Database Connection Error
```bash
# Check PostgreSQL status
docker-compose ps

# View logs
docker-compose logs postgres
```

### High API Latency
- Check Prometheus metrics
- Monitor database query performance
- Review model inference time
- Check system resources

## Contributing

1. Create feature branch
2. Make changes
3. Add tests
4. Run test suite
5. Submit pull request

## License

Proprietary - NeuroScreen AI

## Support

For issues and questions:
- GitHub Issues: [repository]/issues
- Email: support@neuroscreen.ai
- Documentation: [docs-url]

---

**Version**: 1.0.0  
**Last Updated**: 2024-01-15  
**Status**: Production Ready ✅
