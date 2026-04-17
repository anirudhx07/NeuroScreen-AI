"""
API Integration Tests
Tests the wiring between Flutter frontend and ML backend
"""

import pytest
import sys
from pathlib import Path
import numpy as np
from unittest.mock import Mock, patch, MagicMock

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from fastapi.testclient import TestClient
from main import app
from routers.predictions import (
    _extract_features_from_results,
    _get_risk_level,
    _generate_recommendations,
    TestResultData,
    RiskPredictionRequest,
)

client = TestClient(app)


class TestRiskPredictionEndpoint:
    """Tests for the risk prediction endpoint."""

    def test_predict_risk_success(self):
        """Test successful risk prediction."""
        request_data = {
            "test_results": [
                {
                    "user_id": "user123",
                    "test_type": "cognitive",
                    "score": 75.0,
                    "timestamp": "2026-04-17T10:00:00Z",
                },
                {
                    "user_id": "user123",
                    "test_type": "motor",
                    "score": 80.0,
                    "timestamp": "2026-04-17T10:05:00Z",
                },
                {
                    "user_id": "user123",
                    "test_type": "reaction",
                    "score": 400.0,
                    "reaction_time": 400.0,
                    "timestamp": "2026-04-17T10:10:00Z",
                },
                {
                    "user_id": "user123",
                    "test_type": "memory",
                    "score": 75.0,
                    "memory_retention": 75.0,
                    "timestamp": "2026-04-17T10:15:00Z",
                },
                {
                    "user_id": "user123",
                    "test_type": "accuracy",
                    "score": 80.0,
                    "accuracy": 80.0,
                    "timestamp": "2026-04-17T10:20:00Z",
                },
            ],
            "include_confidence": True,
        }

        response = client.post("/api/predictions/risk", json=request_data)

        assert response.status_code == 200
        data = response.json()

        assert "overall_risk_score" in data
        assert "risk_level" in data
        assert data["risk_level"] in ["low", "medium", "high"]
        assert "confidence" in data
        assert 0 <= data["confidence"] <= 1
        assert "recommendations" in data
        assert isinstance(data["recommendations"], list)
        assert "timestamp" in data

    def test_predict_risk_empty_results(self):
        """Test risk prediction with empty results."""
        request_data = {
            "test_results": [],
            "include_confidence": True,
        }

        response = client.post("/api/predictions/risk", json=request_data)

        assert response.status_code == 400
        assert "No test results provided" in response.text

    def test_predict_risk_high_risk_recommendations(self):
        """Test that high-risk predictions generate appropriate recommendations."""
        # Create test results for high-risk patient
        request_data = {
            "test_results": [
                {
                    "user_id": "user123",
                    "test_type": "cognitive",
                    "score": 40.0,  # High risk
                    "timestamp": "2026-04-17T10:00:00Z",
                },
                {
                    "user_id": "user123",
                    "test_type": "motor",
                    "score": 45.0,  # High risk
                    "timestamp": "2026-04-17T10:05:00Z",
                },
                {
                    "user_id": "user123",
                    "test_type": "reaction",
                    "score": 600.0,  # High risk (slow reaction)
                    "reaction_time": 600.0,
                    "timestamp": "2026-04-17T10:10:00Z",
                },
                {
                    "user_id": "user123",
                    "test_type": "memory",
                    "score": 50.0,  # High risk
                    "memory_retention": 50.0,
                    "timestamp": "2026-04-17T10:15:00Z",
                },
                {
                    "user_id": "user123",
                    "test_type": "accuracy",
                    "score": 60.0,  # High risk
                    "accuracy": 60.0,
                    "timestamp": "2026-04-17T10:20:00Z",
                },
            ],
            "include_confidence": True,
        }

        response = client.post("/api/predictions/risk", json=request_data)

        assert response.status_code == 200
        data = response.json()

        # Should generate urgent recommendations
        recommendations = data["recommendations"]
        assert len(recommendations) > 0
        # Check for urgent language
        urgent_found = any("urgent" in rec.lower() or "neurology" in rec.lower()
                          for rec in recommendations)
        assert urgent_found, "High-risk recommendations should include urgent/neurology terms"

    def test_risk_level_classification(self):
        """Test risk level classification."""
        assert _get_risk_level(0.25) == "low"
        assert _get_risk_level(0.75) == "medium"
        assert _get_risk_level(1.75) == "high"

    def test_recommendations_generation(self):
        """Test recommendation generation for each risk level."""
        low_recs = _generate_recommendations("low", 0.25)
        assert len(low_recs) > 0
        assert any("lifestyle" in rec.lower() for rec in low_recs)

        medium_recs = _generate_recommendations("medium", 0.75)
        assert len(medium_recs) > 0
        assert any("neurologist" in rec.lower() for rec in medium_recs)

        high_recs = _generate_recommendations("high", 1.75)
        assert len(high_recs) > 0
        assert any("urgent" in rec.lower() for rec in high_recs)


class TestTrendAnalysisEndpoint:
    """Tests for the trend analysis endpoint."""

    def test_analyze_trends_upward(self):
        """Test upward trend detection."""
        request_data = {
            "scores": [60, 65, 70, 75, 80, 85],
            "forecast_periods": 5,
        }

        response = client.post("/api/analytics/trends", json=request_data)

        assert response.status_code == 200
        data = response.json()

        assert data["direction"] == "up"
        assert data["slope"] > 0
        assert data["strength"] > 0.5
        assert len(data["forecast"]) == 5

    def test_analyze_trends_downward(self):
        """Test downward trend detection."""
        request_data = {
            "scores": [85, 80, 75, 70, 65, 60],
            "forecast_periods": 5,
        }

        response = client.post("/api/analytics/trends", json=request_data)

        assert response.status_code == 200
        data = response.json()

        assert data["direction"] == "down"
        assert data["slope"] < 0
        assert len(data["forecast"]) == 5

    def test_analyze_trends_stable(self):
        """Test stable trend detection."""
        request_data = {
            "scores": [70, 70, 70, 70, 70, 70],
            "forecast_periods": 5,
        }

        response = client.post("/api/analytics/trends", json=request_data)

        assert response.status_code == 200
        data = response.json()

        assert data["direction"] == "stable"
        assert abs(data["slope"]) < 0.2

    def test_analyze_trends_insufficient_data(self):
        """Test trend analysis with insufficient data."""
        request_data = {
            "scores": [70],
            "forecast_periods": 5,
        }

        response = client.post("/api/analytics/trends", json=request_data)

        assert response.status_code == 400


class TestAnomalyDetectionEndpoint:
    """Tests for the anomaly detection endpoint."""

    @pytest.mark.skip(reason="Anomaly detector requires pre-training in separate context")
    def test_detect_anomalies_normal_data(self):
        """Test anomaly detection on normal data."""
        # Train anomaly detector first
        from ml.models import AnomalyDetector
        detector = AnomalyDetector()
        normal_data = np.array([
            [85, 90, 350, 90, 92],
            [84, 89, 355, 88, 91],
            [86, 91, 345, 91, 93],
        ])
        detector.train(normal_data)

        # Normal healthy scores
        request_data = {
            "features": [85, 90, 350, 90, 92],
        }

        response = client.post("/api/analytics/anomalies", json=request_data)

        assert response.status_code == 200
        data = response.json()

        assert "is_anomaly" in data
        assert "anomaly_score" in data
        assert "severity" in data
        assert data["severity"] in ["low", "medium", "high"]

    def test_detect_anomalies_invalid_features(self):
        """Test anomaly detection with invalid feature count."""
        request_data = {
            "features": [85, 90],  # Only 2 features, need at least 5
        }

        response = client.post("/api/analytics/anomalies", json=request_data)

        assert response.status_code == 400


class TestFeatureExtraction:
    """Tests for feature extraction from test results."""

    def test_extract_features_from_cognitive_test(self):
        """Test extracting cognitive feature."""
        results = [
            TestResultData(
                user_id="user123",
                test_type="cognitive",
                score=75.0,
                timestamp="2026-04-17T10:00:00Z",
            )
        ]

        features = _extract_features_from_results(results)

        assert features.shape == (1, 5)
        assert features[0, 0] == 75.0  # Cognitive score at index 0

    def test_extract_features_from_motor_test(self):
        """Test extracting motor feature."""
        results = [
            TestResultData(
                user_id="user123",
                test_type="motor",
                score=80.0,
                motor_score=80.0,
                timestamp="2026-04-17T10:00:00Z",
            )
        ]

        features = _extract_features_from_results(results)

        assert features[0, 1] == 80.0  # Motor score at index 1

    def test_extract_features_from_reaction_time(self):
        """Test extracting reaction time feature."""
        results = [
            TestResultData(
                user_id="user123",
                test_type="reaction_time",
                score=400.0,
                reaction_time=400.0,
                timestamp="2026-04-17T10:00:00Z",
            )
        ]

        features = _extract_features_from_results(results)

        # Reaction time normalized to 0-100 scale
        assert 0 <= features[0, 2] <= 100

    def test_extract_features_complete_assessment(self):
        """Test extracting all features from complete assessment."""
        results = [
            TestResultData(
                user_id="user123",
                test_type="cognitive",
                score=75.0,
                timestamp="2026-04-17T10:00:00Z",
            ),
            TestResultData(
                user_id="user123",
                test_type="motor",
                score=80.0,
                motor_score=80.0,
                timestamp="2026-04-17T10:05:00Z",
            ),
            TestResultData(
                user_id="user123",
                test_type="reaction_time",
                score=400.0,
                reaction_time=400.0,
                timestamp="2026-04-17T10:10:00Z",
            ),
            TestResultData(
                user_id="user123",
                test_type="memory",
                score=75.0,
                memory_retention=75.0,
                timestamp="2026-04-17T10:15:00Z",
            ),
            TestResultData(
                user_id="user123",
                test_type="accuracy",
                score=80.0,
                accuracy=80.0,
                timestamp="2026-04-17T10:20:00Z",
            ),
        ]

        features = _extract_features_from_results(results)

        assert features.shape == (1, 5)
        # All features should be extracted
        assert features[0, 0] == 75.0  # Cognitive
        assert features[0, 1] == 80.0  # Motor
        assert features[0, 3] == 75.0  # Memory
        assert features[0, 4] == 80.0  # Accuracy


class TestHealthCheckEndpoint:
    """Tests for system health endpoint."""

    def test_health_check(self):
        """Test health check endpoint."""
        response = client.get("/health")

        assert response.status_code == 200
        data = response.json()

        assert "status" in data
        assert data["status"] == "healthy"


class TestModelStatusEndpoint:
    """Tests for model status endpoint."""

    @pytest.mark.skip(reason="Model status requires mocking external service")
    def test_model_status(self):
        """Test model status endpoint."""
        response = client.get("/api/models/status")

        assert response.status_code == 200
        data = response.json()

        assert "models" in data or "status" in data


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
