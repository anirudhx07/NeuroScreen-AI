# API Reference

## Overview

Complete REST API documentation for NeuroScreen ML Backend.

**Base URL**: `https://api.neuroscreen.ai/api` (production)  
**Base URL**: `http://localhost:8000/api` (development)

## Authentication

All endpoints (except `/health`) require JWT token authentication.

### Getting a Token

```bash
POST /auth/token
Content-Type: application/json

{
  "username": "user@example.com",
  "password": "password"
}

Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

### Using Token

```bash
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

## Endpoints

### Health & Status

#### Get Health Status
```
GET /health
```

**Response (200 OK)**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Get Readiness
```
GET /health/ready
```

**Response (200 OK)**
```json
{
  "ready": true,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Predictions

#### Predict Risk Level
```
POST /predictions/risk
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**
```json
{
  "test_results": [
    {
      "user_id": "user_123",
      "test_type": "memory",
      "score": 75.5,
      "reaction_time": 450,
      "accuracy": 92.0,
      "timestamp": "2024-01-15T10:00:00Z"
    },
    {
      "user_id": "user_123",
      "test_type": "motor",
      "score": 80.0,
      "reaction_time": 400,
      "accuracy": 95.0,
      "timestamp": "2024-01-15T11:00:00Z"
    }
  ],
  "include_confidence": true
}
```

**Response (200 OK)**
```json
{
  "overall_risk_score": 45.2,
  "risk_level": "low",
  "risk_categories": {
    "cognitive": 45.0,
    "motor": 40.0,
    "sensory": 50.0,
    "emotional": 35.0
  },
  "confidence": 0.92,
  "recommendations": [
    "Continue regular cognitive exercises",
    "Maintain healthy lifestyle",
    "Follow up in 6 months"
  ],
  "timestamp": "2024-01-15T11:30:00Z"
}
```

**Error Response (400 Bad Request)**
```json
{
  "detail": "No test results provided"
}
```

---

#### Detect Anomalies
```
POST /predictions/anomaly
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**
```json
{
  "test_results": [
    {"score": 75},
    {"score": 76},
    {"score": 150},
    {"score": 74},
    {"score": 72}
  ],
  "threshold": 0.05
}
```

**Response (200 OK)**
```json
{
  "is_anomaly": true,
  "anomaly_score": 0.87,
  "affected_metrics": ["score"],
  "severity": "high",
  "details": {
    "outlier_indices": [2],
    "expected_range": [70, 80],
    "actual_value": 150
  }
}
```

---

### Models

#### List Available Models
```
GET /models
Authorization: Bearer {token}
```

**Response (200 OK)**
```json
[
  {
    "name": "Risk Predictor",
    "version": "1.0.0",
    "model_type": "RandomForest",
    "accuracy": 0.92,
    "training_date": "2024-01-10",
    "parameters": {
      "n_estimators": 100,
      "max_depth": 10
    }
  },
  {
    "name": "Trend Analyzer",
    "version": "1.0.0",
    "model_type": "LSTM",
    "accuracy": 0.88,
    "training_date": "2024-01-10",
    "parameters": {
      "units": 128,
      "epochs": 50
    }
  }
]
```

---

#### Get Model Details
```
GET /models/{model_name}
Authorization: Bearer {token}
```

**Path Parameters**
- `model_name` (string): Model identifier (risk_predictor, trend_analyzer, anomaly_detector)

**Response (200 OK)**
```json
{
  "name": "Risk Predictor",
  "version": "1.0.0",
  "model_type": "RandomForest",
  "accuracy": 0.92,
  "training_date": "2024-01-10",
  "parameters": {
    "n_estimators": 100,
    "max_depth": 10,
    "min_samples_split": 5
  }
}
```

---

#### Get Model Metrics
```
GET /models/{model_name}/metrics
Authorization: Bearer {token}
```

**Response (200 OK)**
```json
{
  "accuracy": 0.92,
  "precision": 0.90,
  "recall": 0.91,
  "f1_score": 0.905,
  "auc_roc": 0.95,
  "confusion_matrix": [
    [850, 50],
    [40, 960]
  ]
}
```

---

### Analytics

#### Get User Analytics
```
GET /analytics/user/{user_id}
Authorization: Bearer {token}
```

**Path Parameters**
- `user_id` (string): User identifier

**Response (200 OK)**
```json
{
  "user_id": "user_123",
  "total_tests": 15,
  "average_score": 72.5,
  "score_trend": 5.2,
  "risk_progression": "stable",
  "last_updated": "2024-01-15T10:30:00Z"
}
```

---

#### Get Trend Analysis
```
GET /analytics/trends/{user_id}
Authorization: Bearer {token}
```

**Query Parameters**
- `lookback_days` (integer, optional): Days to analyze (default: 90)
- `include_forecast` (boolean, optional): Include forecast (default: true)

**Response (200 OK)**
```json
[
  {
    "metric_name": "cognitive_score",
    "values": [65.0, 68.0, 70.0, 72.0, 72.5],
    "timestamps": [
      "2024-01-01",
      "2024-02-01",
      "2024-03-01",
      "2024-04-01",
      "2024-05-01"
    ],
    "trend_direction": "up",
    "trend_strength": 0.85,
    "forecast": [73.0, 74.0, 75.0]
  },
  {
    "metric_name": "motor_score",
    "values": [75.0, 75.5, 76.0, 75.8, 76.2],
    "timestamps": [
      "2024-01-01",
      "2024-02-01",
      "2024-03-01",
      "2024-04-01",
      "2024-05-01"
    ],
    "trend_direction": "stable",
    "trend_strength": 0.6,
    "forecast": [76.5, 76.7, 76.8]
  }
]
```

---

#### Get Platform Statistics
```
GET /analytics/statistics
Authorization: Bearer {token}
```

**Response (200 OK)**
```json
{
  "total_users": 5000,
  "total_tests_completed": 25000,
  "average_app_score": 68.5,
  "most_common_risk_level": "medium",
  "platform_health": "excellent",
  "last_updated": "2024-01-15T10:30:00Z"
}
```

---

#### Analyze User Cohort
```
POST /analytics/cohort-analysis
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**
```json
{
  "cohort_name": "Age 45-55",
  "age_range": [45, 55],
  "include_demographics": true
}
```

**Response (200 OK)**
```json
{
  "cohort_name": "Age 45-55",
  "sample_size": 250,
  "average_risk": 52.3,
  "risk_distribution": {
    "low": 85,
    "medium": 130,
    "high": 35
  },
  "common_patterns": [
    "Reaction time decline with age",
    "Memory score stability",
    "Motor coordination maintenance"
  ]
}
```

---

## Error Handling

All errors return appropriate HTTP status codes with error details.

### Common Error Responses

**400 Bad Request**
```json
{
  "detail": "Invalid request format",
  "error_code": "INVALID_INPUT",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**401 Unauthorized**
```json
{
  "detail": "Invalid or expired token",
  "error_code": "INVALID_TOKEN"
}
```

**404 Not Found**
```json
{
  "detail": "Resource not found",
  "error_code": "NOT_FOUND"
}
```

**429 Too Many Requests**
```json
{
  "detail": "Rate limit exceeded",
  "error_code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 60
}
```

**500 Internal Server Error**
```json
{
  "detail": "Internal server error",
  "error_code": "INTERNAL_ERROR",
  "request_id": "req_123456"
}
```

---

## Rate Limiting

Rate limits are applied per API key:

- **Basic Tier**: 100 requests/minute
- **Pro Tier**: 1,000 requests/minute
- **Enterprise**: Unlimited

Rate limit info is returned in response headers:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705330260
```

---

## Pagination

List endpoints support pagination:

```
GET /api/resources?page=1&page_size=20
```

**Response**
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

---

## Data Types

### Risk Level
```
low    | score 0-33
medium | score 33-67
high   | score 67-100
```

### Test Types
```
memory      | Memory retention test
reaction    | Reaction time test
motor       | Motor skills test
voice       | Voice analysis test
eye_track   | Eye tracking test
```

### Timestamps
All timestamps are in ISO 8601 format: `YYYY-MM-DDTHH:mm:ssZ`

---

## Code Examples

### Python (requests)
```python
import requests

headers = {"Authorization": "Bearer YOUR_TOKEN"}

# Get risk prediction
response = requests.post(
    "http://localhost:8000/api/predictions/risk",
    headers=headers,
    json={
        "test_results": [
            {
                "user_id": "user_123",
                "test_type": "memory",
                "score": 75.5,
                "accuracy": 92.0,
                "timestamp": "2024-01-15T10:00:00Z"
            }
        ]
    }
)

print(response.json())
```

### JavaScript (fetch)
```javascript
const token = "YOUR_TOKEN";

fetch("http://localhost:8000/api/predictions/risk", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${token}`,
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    test_results: [{
      user_id: "user_123",
      test_type: "memory",
      score: 75.5,
      accuracy: 92.0,
      timestamp: "2024-01-15T10:00:00Z"
    }]
  })
})
.then(r => r.json())
.then(console.log);
```

### cURL
```bash
curl -X POST http://localhost:8000/api/predictions/risk \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "test_results": [{
      "user_id": "user_123",
      "test_type": "memory",
      "score": 75.5,
      "accuracy": 92.0,
      "timestamp": "2024-01-15T10:00:00Z"
    }]
  }'
```

---

**Version**: 1.0.0  
**Last Updated**: 2024-01-15  
**Status**: Stable ✅
