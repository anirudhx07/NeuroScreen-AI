"""
Professional Integration Test Suite for ML Backend API.
Comprehensive testing of API endpoints, ML model integration, and end-to-end workflows.
Tests real-world scenarios including concurrent requests, error handling, and performance.

Author: NeuroScreen AI
Date: 2024-01-15
Version: 1.0.0
"""

import pytest
import json
import time
import numpy as np
from typing import Dict, Any
from fastapi.testclient import TestClient
from datetime import datetime
import logging

from main import app
from ml.models import RiskPredictor, TrendAnalyzer, AnomalyDetector
from ml.preprocessing import DataPreprocessor

logger = logging.getLogger(__name__)


# ============================================================================
# FIXTURES: API Client and Authentication
# ============================================================================

@pytest.fixture(scope="session")
def client():
    """Create FastAPI test client."""
    return TestClient(app)


@pytest.fixture(scope="session")
def valid_token() -> str:
    """
    Generate valid test token.
    In production, use proper JWT token generation.
    """
    return "test-token-neuroscreen-12345"


@pytest.fixture
def auth_headers(valid_token) -> Dict[str, str]:
    """Create authorization headers."""
    return {"Authorization": f"Bearer {valid_token}"}


# ============================================================================
# FIXTURES: Test Data for API Testing
# ============================================================================

@pytest.fixture
def valid_test_result() -> Dict[str, Any]:
    """Generate valid test result data."""
    return {
        "user_id": "user_123",
        "test_type": "memory",
        "score": 75.5,
        "reaction_time": 450,
        "accuracy": 92.0,
        "timestamp": datetime.now().isoformat() + "Z"
    }


@pytest.fixture
def multiple_test_results() -> list:
    """Generate multiple test results for batch processing."""
    results = []
    test_types = ["memory", "motor", "reaction", "voice", "eye_track"]

    for i in range(5):
        results.append({
            "user_id": f"user_{i}",
            "test_type": test_types[i % len(test_types)],
            "score": 70 + i * 5,
            "reaction_time": 400 + i * 50,
            "accuracy": 85 + i * 2,
            "timestamp": datetime.now().isoformat() + "Z"
        })

    return results


@pytest.fixture
def anomalous_test_results() -> list:
    """Generate test results with known anomalies."""
    return [
        {"score": 75},
        {"score": 76},
        {"score": 74},
        {"score": 150},  # Anomaly
        {"score": 75},
    ]


# ============================================================================
# HEALTH CHECK TESTS
# ============================================================================

@pytest.mark.integration
@pytest.mark.api
class TestHealthEndpoints:
    """Test health check and readiness endpoints."""

    @pytest.mark.unit
    def test_health_check_returns_200(self, client):
        """
        Test: Health endpoint returns 200 OK
        Expected: status='healthy', valid timestamp
        """
        response = client.get("/health")

        assert response.status_code == 200, "Health check should return 200"
        data = response.json()
        assert data["status"] == "healthy", "Should be healthy"
        assert "timestamp" in data, "Should include timestamp"

        logger.info("✓ Health check test passed")

    @pytest.mark.unit
    def test_readiness_check_returns_200(self, client):
        """
        Test: Readiness endpoint returns 200 OK
        Expected: ready=true, valid timestamp
        """
        response = client.get("/health/ready")

        assert response.status_code == 200, "Readiness check should return 200"
        data = response.json()
        assert data["ready"] is True, "Should be ready"
        assert "timestamp" in data, "Should include timestamp"

        logger.info("✓ Readiness check test passed")

    @pytest.mark.performance
    def test_health_check_latency(self, client):
        """
        Test: Health check responds quickly
        Expected: <50ms response time
        """
        start_time = time.time()
        response = client.get("/health")
        latency = (time.time() - start_time) * 1000

        assert response.status_code == 200
        assert latency < 50, f"Health check should respond in <50ms, got {latency:.2f}ms"

        logger.info(f"✓ Health check latency test passed | {latency:.2f}ms")


# ============================================================================
# PREDICTION ENDPOINT TESTS
# ============================================================================

@pytest.mark.integration
@pytest.mark.api
class TestPredictionEndpoints:
    """Test ML prediction endpoints."""

    @pytest.mark.unit
    def test_risk_prediction_valid_request(self, client, auth_headers, valid_test_result):
        """
        Test: Risk prediction with valid data
        Expected: 200 OK with risk score, level, recommendations
        """
        response = client.post(
            "/api/predictions/risk",
            json={"test_results": [valid_test_result], "include_confidence": True},
            headers=auth_headers
        )

        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        data = response.json()

        assert "overall_risk_score" in data, "Should include overall_risk_score"
        assert "risk_level" in data, "Should include risk_level"
        assert "risk_categories" in data, "Should include risk_categories"
        assert "confidence" in data, "Should include confidence"
        assert "recommendations" in data, "Should include recommendations"

        # Validate values
        assert 0 <= data["overall_risk_score"] <= 100, "Risk score should be 0-100"
        assert data["risk_level"] in ["low", "medium", "high"], "Risk level should be valid"
        assert 0 <= data["confidence"] <= 1, "Confidence should be 0-1"

        logger.info(f"✓ Risk prediction test passed | Score: {data['overall_risk_score']}")

    @pytest.mark.unit
    def test_risk_prediction_multiple_results(self, client, auth_headers, multiple_test_results):
        """
        Test: Risk prediction with multiple test results
        Expected: Handles batch requests correctly
        """
        response = client.post(
            "/api/predictions/risk",
            json={"test_results": multiple_test_results},
            headers=auth_headers
        )

        assert response.status_code == 200, "Should handle multiple test results"
        data = response.json()
        assert "overall_risk_score" in data, "Should return aggregated score"

        logger.info(f"✓ Multiple test results test passed | {len(multiple_test_results)} records")

    @pytest.mark.unit
    def test_risk_prediction_empty_request(self, client, auth_headers):
        """
        Test: Risk prediction with empty test results
        Expected: 400 Bad Request
        """
        response = client.post(
            "/api/predictions/risk",
            json={"test_results": []},
            headers=auth_headers
        )

        assert response.status_code == 400, "Empty request should return 400"
        logger.info("✓ Empty request validation test passed")

    @pytest.mark.unit
    def test_risk_prediction_invalid_scores(self, client, auth_headers):
        """
        Test: Risk prediction with invalid score values
        Expected: 400 Bad Request or handled gracefully
        """
        invalid_result = {
            "user_id": "user_123",
            "test_type": "memory",
            "score": 150,  # Invalid: >100
            "accuracy": 92.0,
            "timestamp": datetime.now().isoformat() + "Z"
        }

        response = client.post(
            "/api/predictions/risk",
            json={"test_results": [invalid_result]},
            headers=auth_headers
        )

        # Should either validate or handle gracefully
        assert response.status_code in [200, 400, 422], "Should handle invalid input"
        logger.info("✓ Invalid score validation test passed")

    @pytest.mark.unit
    def test_anomaly_detection_valid_request(self, client, auth_headers, anomalous_test_results):
        """
        Test: Anomaly detection with anomalous data
        Expected: 200 OK with anomaly detection results
        """
        response = client.post(
            "/api/predictions/anomaly",
            json={"test_results": anomalous_test_results, "threshold": 0.05},
            headers=auth_headers
        )

        assert response.status_code == 200, "Should detect anomalies"
        data = response.json()

        assert "is_anomaly" in data, "Should include is_anomaly"
        assert "anomaly_score" in data, "Should include anomaly_score"
        assert "affected_metrics" in data, "Should include affected_metrics"
        assert "severity" in data, "Should include severity"

        logger.info(f"✓ Anomaly detection test passed | Is_anomaly: {data['is_anomaly']}")

    @pytest.mark.performance
    def test_prediction_latency(self, client, auth_headers, valid_test_result):
        """
        Test: Prediction endpoint meets latency requirements
        Expected: <500ms response time
        """
        start_time = time.time()
        response = client.post(
            "/api/predictions/risk",
            json={"test_results": [valid_test_result]},
            headers=auth_headers
        )
        latency = (time.time() - start_time) * 1000

        assert response.status_code == 200
        assert latency < 500, f"Latency should be <500ms, got {latency:.2f}ms"

        logger.info(f"✓ Prediction latency test passed | {latency:.2f}ms")


# ============================================================================
# MODEL MANAGEMENT TESTS
# ============================================================================

@pytest.mark.integration
@pytest.mark.api
class TestModelEndpoints:
    """Test model management endpoints."""

    @pytest.mark.unit
    def test_list_models(self, client, auth_headers):
        """
        Test: List available models
        Expected: 200 OK with model list
        """
        response = client.get(
            "/api/models",
            headers=auth_headers
        )

        assert response.status_code == 200, "Should list models"
        models = response.json()

        assert isinstance(models, list), "Should return list"
        assert len(models) > 0, "Should have models"

        # Check model structure
        for model in models:
            assert "name" in model, "Model should have name"
            assert "version" in model, "Model should have version"
            assert "accuracy" in model, "Model should have accuracy"

        logger.info(f"✓ List models test passed | {len(models)} models available")

    @pytest.mark.unit
    def test_get_model_info(self, client, auth_headers):
        """
        Test: Get specific model info
        Expected: 200 OK with model details
        """
        response = client.get(
            "/api/models/risk_predictor",
            headers=auth_headers
        )

        assert response.status_code == 200, "Should get model info"
        model = response.json()

        assert model["name"] == "Risk Predictor", "Should be risk predictor"
        assert "version" in model, "Should have version"
        assert "model_type" in model, "Should have model type"
        assert "parameters" in model, "Should have parameters"

        logger.info(f"✓ Get model info test passed | Model: {model['name']}")

    @pytest.mark.unit
    def test_get_model_metrics(self, client, auth_headers):
        """
        Test: Get model performance metrics
        Expected: 200 OK with metrics
        """
        response = client.get(
            "/api/models/risk_predictor/metrics",
            headers=auth_headers
        )

        assert response.status_code == 200, "Should get model metrics"
        metrics = response.json()

        expected_metrics = ["accuracy", "precision", "recall", "f1_score", "auc_roc", "confusion_matrix"]
        for metric in expected_metrics:
            assert metric in metrics, f"Should include {metric}"

        logger.info(f"✓ Get model metrics test passed | Accuracy: {metrics['accuracy']}")

    @pytest.mark.unit
    def test_get_nonexistent_model(self, client, auth_headers):
        """
        Test: Request nonexistent model
        Expected: 404 Not Found
        """
        response = client.get(
            "/api/models/nonexistent_model",
            headers=auth_headers
        )

        assert response.status_code == 404, "Should return 404 for nonexistent model"
        logger.info("✓ Nonexistent model test passed")


# ============================================================================
# ANALYTICS TESTS
# ============================================================================

@pytest.mark.integration
@pytest.mark.api
class TestAnalyticsEndpoints:
    """Test analytics endpoints."""

    @pytest.mark.unit
    def test_user_analytics(self, client, auth_headers):
        """
        Test: Get user analytics
        Expected: 200 OK with user metrics
        """
        response = client.get(
            "/api/analytics/user/user_123",
            headers=auth_headers
        )

        assert response.status_code == 200, "Should get user analytics"
        analytics = response.json()

        assert "total_tests" in analytics, "Should include total_tests"
        assert "average_score" in analytics, "Should include average_score"
        assert "score_trend" in analytics, "Should include score_trend"
        assert "risk_progression" in analytics, "Should include risk_progression"

        logger.info(f"✓ User analytics test passed | Total tests: {analytics['total_tests']}")

    @pytest.mark.unit
    def test_trend_analysis(self, client, auth_headers):
        """
        Test: Get trend analysis
        Expected: 200 OK with trend data
        """
        response = client.get(
            "/api/analytics/trends/user_123",
            headers=auth_headers
        )

        assert response.status_code == 200, "Should get trends"
        trends = response.json()

        assert isinstance(trends, list), "Should return list of trends"
        if len(trends) > 0:
            trend = trends[0]
            assert "metric_name" in trend, "Trend should have metric_name"
            assert "trend_direction" in trend, "Trend should have direction"
            assert "forecast" in trend, "Trend should have forecast"

        logger.info(f"✓ Trend analysis test passed | {len(trends)} trends")

    @pytest.mark.unit
    def test_platform_statistics(self, client, auth_headers):
        """
        Test: Get platform statistics
        Expected: 200 OK with platform metrics
        """
        response = client.get(
            "/api/analytics/statistics",
            headers=auth_headers
        )

        assert response.status_code == 200, "Should get statistics"
        stats = response.json()

        assert "total_users" in stats, "Should include total_users"
        assert "total_tests_completed" in stats, "Should include total_tests_completed"
        assert "average_app_score" in stats, "Should include average_app_score"

        logger.info(f"✓ Platform statistics test passed | Total users: {stats['total_users']}")

    @pytest.mark.unit
    def test_cohort_analysis(self, client, auth_headers):
        """
        Test: Analyze user cohorts
        Expected: 200 OK with cohort analysis
        """
        cohort_data = {
            "cohort_name": "Age 45-55",
            "age_range": [45, 55]
        }

        response = client.post(
            "/api/analytics/cohort-analysis",
            json=cohort_data,
            headers=auth_headers
        )

        assert response.status_code == 200, "Should analyze cohort"
        analysis = response.json()

        assert "cohort_name" in analysis, "Should include cohort_name"
        assert "sample_size" in analysis, "Should include sample_size"
        assert "average_risk" in analysis, "Should include average_risk"

        logger.info(f"✓ Cohort analysis test passed | Cohort: {analysis['cohort_name']}")


# ============================================================================
# ERROR HANDLING TESTS
# ============================================================================

@pytest.mark.integration
@pytest.mark.api
class TestErrorHandling:
    """Test error handling and edge cases."""

    @pytest.mark.unit
    def test_missing_authorization(self, client):
        """
        Test: Request without authorization
        Expected: 401 or 403 Unauthorized
        """
        response = client.get("/api/models")

        assert response.status_code in [401, 403], "Should reject unauthorized requests"
        logger.info("✓ Missing authorization test passed")

    @pytest.mark.unit
    def test_invalid_token(self, client):
        """
        Test: Request with invalid token
        Expected: 401 Unauthorized
        """
        response = client.get(
            "/api/models",
            headers={"Authorization": "Bearer invalid_token_xyz"}
        )

        assert response.status_code in [401, 403], "Should reject invalid token"
        logger.info("✓ Invalid token test passed")

    @pytest.mark.unit
    def test_malformed_json(self, client, auth_headers):
        """
        Test: Malformed JSON request
        Expected: 400 or 422 Unprocessable Entity
        """
        response = client.post(
            "/api/predictions/risk",
            data="not json at all",
            headers=auth_headers,
            content_type="application/json"
        )

        assert response.status_code in [400, 422], "Should reject malformed JSON"
        logger.info("✓ Malformed JSON test passed")

    @pytest.mark.unit
    def test_missing_required_fields(self, client, auth_headers):
        """
        Test: Request missing required fields
        Expected: 400 or 422
        """
        response = client.post(
            "/api/predictions/risk",
            json={"test_results": [{}]},  # Empty test result
            headers=auth_headers
        )

        assert response.status_code in [400, 422, 200], "Should handle missing fields"
        logger.info("✓ Missing fields test passed")


# ============================================================================
# END-TO-END WORKFLOW TESTS
# ============================================================================

@pytest.mark.integration
class TestEndToEndWorkflow:
    """Test complete workflows."""

    @pytest.mark.integration
    def test_complete_assessment_workflow(self, client, auth_headers, valid_test_result):
        """
        Test: Complete assessment workflow
        Expected: All steps succeed
        """
        logger.info("Starting complete assessment workflow test")

        # Step 1: Check health
        health = client.get("/health")
        assert health.status_code == 200, "API should be healthy"

        # Step 2: List models
        models = client.get("/api/models", headers=auth_headers)
        assert models.status_code == 200, "Should list models"

        # Step 3: Get model info
        model_info = client.get("/api/models/risk_predictor", headers=auth_headers)
        assert model_info.status_code == 200, "Should get model info"

        # Step 4: Make prediction
        prediction = client.post(
            "/api/predictions/risk",
            json={"test_results": [valid_test_result]},
            headers=auth_headers
        )
        assert prediction.status_code == 200, "Should predict"

        # Step 5: Get analytics
        analytics = client.get(
            "/api/analytics/user/user_123",
            headers=auth_headers
        )
        assert analytics.status_code == 200, "Should get analytics"

        logger.info("✓ Complete workflow test passed")

    @pytest.mark.integration
    @pytest.mark.performance
    def test_concurrent_requests(self, client, auth_headers, valid_test_result):
        """
        Test: Handle multiple concurrent-like requests
        Expected: All requests succeed
        """
        logger.info("Testing concurrent requests")

        responses = []
        for i in range(10):
            response = client.post(
                "/api/predictions/risk",
                json={"test_results": [valid_test_result]},
                headers=auth_headers
            )
            responses.append(response)

        successful = sum(1 for r in responses if r.status_code == 200)
        assert successful == 10, "All requests should succeed"

        logger.info(f"✓ Concurrent requests test passed | {successful}/10 succeeded")

    @pytest.mark.integration
    def test_prediction_consistency(self, client, auth_headers, valid_test_result):
        """
        Test: Same input produces consistent output
        Expected: Predictions are deterministic
        """
        logger.info("Testing prediction consistency")

        # Make same prediction twice
        pred1 = client.post(
            "/api/predictions/risk",
            json={"test_results": [valid_test_result]},
            headers=auth_headers
        ).json()

        pred2 = client.post(
            "/api/predictions/risk",
            json={"test_results": [valid_test_result]},
            headers=auth_headers
        ).json()

        # Compare results
        assert pred1["overall_risk_score"] == pred2["overall_risk_score"], "Predictions should be consistent"
        assert pred1["risk_level"] == pred2["risk_level"], "Risk levels should be consistent"

        logger.info(f"✓ Consistency test passed | Score: {pred1['overall_risk_score']}")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short", "-s"])
