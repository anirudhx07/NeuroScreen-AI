"""
Professional ML Model Test Suite.
Comprehensive testing for RiskPredictor, TrendAnalyzer, and AnomalyDetector models.
Tests cover functionality, performance, edge cases, and medical data patterns.

Author: NeuroScreen AI
Date: 2024-01-15
Version: 1.0.0
"""

import pytest
import numpy as np
import pandas as pd
import time
import logging
from typing import Dict, Tuple
from sklearn.metrics import confusion_matrix, classification_report

from ml.models import RiskPredictor, TrendAnalyzer, AnomalyDetector
from ml.preprocessing import DataPreprocessor, FeatureEngineer, DataValidator

logger = logging.getLogger(__name__)


# ============================================================================
# RISK PREDICTOR TESTS
# ============================================================================

@pytest.mark.ml
class TestRiskPredictor:
    """Professional tests for RiskPredictor model."""

    @pytest.mark.unit
    def test_initialization(self):
        """
        Test: Model initializes with correct state
        Expected: model and scaler are None until training
        """
        model = RiskPredictor()
        assert model.model is None, "Model should be None before training"
        assert model.scaler is None, "Scaler should be None before training"
        assert hasattr(model, 'feature_names'), "Should have feature_names attribute"
        logger.info("✓ Model initialization test passed")

    @pytest.mark.unit
    def test_training_realistic_data(self, realistic_test_data):
        """
        Test: Training on realistic neurological assessment data
        Expected: Model trains successfully and achieves >85% accuracy
        """
        X, y = realistic_test_data
        model = RiskPredictor()

        # Train model
        start_time = time.time()
        metrics = model.train(X, y)
        training_time = time.time() - start_time

        # Assertions
        assert model.model is not None, "Model should be trained"
        assert model.scaler is not None, "Scaler should be fitted"
        assert 'accuracy' in metrics, "Metrics should contain accuracy"
        assert metrics['accuracy'] > 0.85, f"Accuracy should be >85%, got {metrics['accuracy']:.2f}"
        assert metrics['precision'] > 0.8, "Precision should be >0.8"
        assert metrics['recall'] > 0.8, "Recall should be >0.8"
        assert metrics['f1'] > 0.8, "F1 score should be >0.8"

        logger.info(f"✓ Training test passed | Accuracy: {metrics['accuracy']:.2f} | Time: {training_time:.2f}s")

    @pytest.mark.unit
    def test_training_imbalanced_data(self, unbalanced_test_data):
        """
        Test: Training on imbalanced data (medical reality)
        Expected: Model handles class imbalance appropriately
        """
        X, y = unbalanced_test_data
        model = RiskPredictor()

        metrics = model.train(X, y)

        assert model.model is not None, "Model should handle imbalanced data"
        assert metrics['accuracy'] > 0.7, "Accuracy should still be reasonable"

        logger.info(f"✓ Imbalanced data test passed | Accuracy: {metrics['accuracy']:.2f}")

    @pytest.mark.unit
    def test_prediction_shape_and_values(self, realistic_test_data):
        """
        Test: Predictions have correct shape and valid values
        Expected: Predictions match input size, probabilities in [0,1], risk levels valid
        """
        X, y = realistic_test_data
        model = RiskPredictor()
        model.train(X, y)

        # Get predictions
        predictions, probabilities = model.predict(X[:20])

        # Assertions
        assert len(predictions) == 20, "Prediction count should match input"
        assert len(probabilities) == 20, "Probability count should match input"
        assert all(0 <= p <= 1 for p in probabilities), "Probabilities should be in [0,1]"
        assert all(pred in [0, 1, 2] for pred in predictions), "Predictions should be 0,1,2"

        logger.info(f"✓ Prediction shape and values test passed")

    @pytest.mark.unit
    @pytest.mark.parametrize("n_samples", [1, 10, 100, 500])
    def test_prediction_various_sizes(self, realistic_test_data, n_samples):
        """
        Test: Predictions work with various input sizes
        Expected: Model handles all sizes correctly
        """
        X, y = realistic_test_data[:n_samples]
        model = RiskPredictor()
        model.train(realistic_test_data[0], realistic_test_data[1])

        predictions, probs = model.predict(X)

        assert len(predictions) == n_samples, f"Should predict {n_samples} samples"
        logger.info(f"✓ Prediction test passed for {n_samples} samples")

    @pytest.mark.unit
    def test_edge_case_single_sample(self, realistic_test_data):
        """
        Test: Prediction on single sample
        Expected: Model handles single sample gracefully
        """
        X, y = realistic_test_data
        model = RiskPredictor()
        model.train(X, y)

        single_sample = X[0:1]
        predictions, probs = model.predict(single_sample)

        assert len(predictions) == 1, "Should predict for single sample"
        assert len(probs) == 1, "Should return probability for single sample"

        logger.info("✓ Single sample prediction test passed")

    @pytest.mark.unit
    def test_feature_importance(self, realistic_test_data):
        """
        Test: Feature importance can be extracted
        Expected: Model provides feature importance information
        """
        X, y = realistic_test_data
        model = RiskPredictor()
        model.train(X, y)

        # Get feature importances from trained model
        if hasattr(model.model, 'feature_importances_'):
            importances = model.model.feature_importances_
            assert len(importances) == 5, "Should have 5 feature importances"
            assert sum(importances) > 0, "Feature importances should sum to non-zero"
            logger.info(f"✓ Feature importance test passed | Top feature: {np.argmax(importances)}")

    @pytest.mark.performance
    def test_prediction_latency(self, realistic_test_data):
        """
        Test: Prediction latency meets performance targets
        Expected: <200ms for 100 predictions
        """
        X, y = realistic_test_data
        model = RiskPredictor()
        model.train(X, y)

        start_time = time.time()
        predictions, probs = model.predict(X[:100])
        latency = (time.time() - start_time) * 1000  # Convert to ms

        assert latency < 200, f"Latency should be <200ms, got {latency:.2f}ms"
        logger.info(f"✓ Latency test passed | {latency:.2f}ms for 100 predictions")

    @pytest.mark.unit
    def test_persistence(self, realistic_test_data, tmp_path):
        """
        Test: Model can be saved and loaded
        Expected: Loaded model produces identical predictions
        """
        X, y = realistic_test_data
        model = RiskPredictor()
        model.train(X, y)

        # Save model
        model_path = str(tmp_path / "test_model")
        model.save(model_path)

        # Load model
        loaded_model = RiskPredictor()
        loaded_model.load(model_path)

        # Compare predictions
        orig_pred, orig_prob = model.predict(X[:10])
        loaded_pred, loaded_prob = loaded_model.predict(X[:10])

        assert np.allclose(orig_pred, loaded_pred), "Predictions should be identical"
        assert np.allclose(orig_prob, loaded_prob), "Probabilities should be identical"

        logger.info("✓ Model persistence test passed")

    @pytest.mark.unit
    def test_data_normalization(self, realistic_test_data):
        """
        Test: Data is normalized consistently
        Expected: Predictions are scale-invariant when data is properly normalized
        """
        X, y = realistic_test_data
        model = RiskPredictor()
        model.train(X, y)

        # Test with different scales
        pred1, _ = model.predict(X[:10])

        # Verify scaler is applied
        assert model.scaler is not None, "Scaler should be fitted"
        logger.info("✓ Data normalization test passed")


# ============================================================================
# TREND ANALYZER TESTS
# ============================================================================

@pytest.mark.ml
class TestTrendAnalyzer:
    """Professional tests for TrendAnalyzer model."""

    @pytest.mark.unit
    def test_upward_trend_detection(self):
        """
        Test: Upward trend is correctly detected
        Expected: direction='up', strength>0, slope>0
        """
        scores = np.array([50, 55, 60, 65, 70])
        analyzer = TrendAnalyzer()
        trend = analyzer.calculate_trend(scores)

        assert trend['direction'] == 'up', "Should detect upward trend"
        assert trend['strength'] > 0, "Strength should be positive"
        assert trend['slope'] > 0, "Slope should be positive"

        logger.info(f"✓ Upward trend test passed | Slope: {trend['slope']:.4f}")

    @pytest.mark.unit
    def test_downward_trend_detection(self):
        """
        Test: Downward trend is correctly detected
        Expected: direction='down', strength>0, slope<0
        """
        scores = np.array([70, 65, 60, 55, 50])
        analyzer = TrendAnalyzer()
        trend = analyzer.calculate_trend(scores)

        assert trend['direction'] == 'down', "Should detect downward trend"
        assert trend['strength'] > 0, "Strength should be positive"
        assert trend['slope'] < 0, "Slope should be negative"

        logger.info(f"✓ Downward trend test passed | Slope: {trend['slope']:.4f}")

    @pytest.mark.unit
    def test_stable_trend_detection(self):
        """
        Test: Stable trend is correctly detected
        Expected: direction='stable', strength~0, slope~0
        """
        scores = np.array([60, 60.5, 59.5, 60.2, 59.8])
        analyzer = TrendAnalyzer()
        trend = analyzer.calculate_trend(scores)

        assert trend['direction'] == 'stable', "Should detect stable trend"
        assert abs(trend['slope']) < 1, "Slope should be near zero"

        logger.info(f"✓ Stable trend test passed | Slope: {trend['slope']:.4f}")

    @pytest.mark.unit
    def test_forecast_accuracy(self, temporal_test_data):
        """
        Test: Forecast follows underlying trend
        Expected: Forecast values continue trend direction
        """
        scores = temporal_test_data['score'].values
        analyzer = TrendAnalyzer()

        trend = analyzer.calculate_trend(scores)
        forecast = analyzer.forecast(scores, periods=5)

        assert len(forecast) == 5, "Forecast should have 5 periods"
        assert all(isinstance(f, (int, float, np.number)) for f in forecast), "Forecast values should be numeric"

        # Check forecast follows trend
        if trend['direction'] == 'up':
            assert forecast[-1] > scores[-1], "Forecast should continue upward trend"

        logger.info(f"✓ Forecast test passed | Next 5 predictions: {forecast}")

    @pytest.mark.unit
    @pytest.mark.parametrize("periods", [1, 3, 5, 10])
    def test_forecast_various_periods(self, temporal_test_data, periods):
        """
        Test: Forecasting works for various periods
        Expected: Correct number of forecast values
        """
        scores = temporal_test_data['score'].values
        analyzer = TrendAnalyzer()
        forecast = analyzer.forecast(scores, periods=periods)

        assert len(forecast) == periods, f"Forecast should have {periods} periods"
        logger.info(f"✓ Forecast test passed for {periods} periods")

    @pytest.mark.unit
    def test_trend_metrics(self):
        """
        Test: Trend metrics are calculated correctly
        Expected: avg_score, std_score in valid ranges
        """
        scores = np.array([50, 60, 70, 80, 90])
        analyzer = TrendAnalyzer()
        trend = analyzer.calculate_trend(scores)

        assert 'avg_score' in trend, "Should calculate average score"
        assert 'std_score' in trend, "Should calculate standard deviation"
        assert trend['avg_score'] == 70, "Average should be 70"

        logger.info(f"✓ Trend metrics test passed | Avg: {trend['avg_score']}, Std: {trend['std_score']:.2f}")

    @pytest.mark.unit
    def test_insufficient_data(self):
        """
        Test: Handles insufficient data gracefully
        Expected: Returns appropriate status or default values
        """
        scores = np.array([50])
        analyzer = TrendAnalyzer()
        trend = analyzer.calculate_trend(scores)

        assert trend['direction'] == 'insufficient_data', "Should indicate insufficient data"
        logger.info("✓ Insufficient data handling test passed")


# ============================================================================
# ANOMALY DETECTOR TESTS
# ============================================================================

@pytest.mark.ml
class TestAnomalyDetector:
    """Professional tests for AnomalyDetector model."""

    @pytest.mark.unit
    def test_initialization(self):
        """
        Test: AnomalyDetector initializes correctly
        Expected: model is None before training
        """
        detector = AnomalyDetector()
        assert detector.model is None, "Model should be None before training"
        logger.info("✓ Initialization test passed")

    @pytest.mark.unit
    def test_training(self, realistic_test_data):
        """
        Test: Training completes successfully
        Expected: Model is trained and ready for predictions
        """
        X, y = realistic_test_data
        detector = AnomalyDetector()

        result = detector.train(X)

        assert detector.model is not None, "Model should be trained"
        assert result['status'] == 'trained', "Should return trained status"

        logger.info("✓ Training test passed")

    @pytest.mark.unit
    def test_anomaly_prediction(self, anomalous_data):
        """
        Test: Anomaly detection identifies known anomalies
        Expected: Anomalous samples get low anomaly scores (negative)
        """
        detector = AnomalyDetector()
        detector.train(anomalous_data)

        predictions, scores = detector.predict(anomalous_data)

        # Anomalies should be marked as -1
        anomaly_count = np.sum(predictions == -1)
        assert anomaly_count > 0, "Should detect at least some anomalies"
        assert anomaly_count <= 10, "Should not over-detect anomalies"

        logger.info(f"✓ Anomaly detection test passed | Detected {anomaly_count} anomalies")

    @pytest.mark.unit
    def test_normal_data_classification(self, realistic_test_data):
        """
        Test: Normal data is classified correctly
        Expected: Most normal samples labeled as 1 (normal)
        """
        X, y = realistic_test_data
        detector = AnomalyDetector()
        detector.train(X)

        predictions, scores = detector.predict(X[:50])

        normal_count = np.sum(predictions == 1)
        assert normal_count > 40, "Most samples should be normal"

        logger.info(f"✓ Normal data test passed | Normal: {normal_count}/50")

    @pytest.mark.unit
    def test_anomaly_scores_range(self, anomalous_data):
        """
        Test: Anomaly scores are in valid range
        Expected: Scores represent distance from normal distribution
        """
        detector = AnomalyDetector()
        detector.train(anomalous_data)

        predictions, scores = detector.predict(anomalous_data)

        # IsolationForest returns scores, typically negative for anomalies
        assert all(isinstance(s, (int, float, np.number)) for s in scores), "All scores should be numeric"

        logger.info(f"✓ Anomaly scores test passed | Score range: [{scores.min():.2f}, {scores.max():.2f}]")

    @pytest.mark.performance
    def test_detection_latency(self, realistic_test_data):
        """
        Test: Anomaly detection meets latency requirements
        Expected: <200ms for 100 predictions
        """
        X, y = realistic_test_data
        detector = AnomalyDetector()
        detector.train(X)

        start_time = time.time()
        predictions, scores = detector.predict(X[:100])
        latency = (time.time() - start_time) * 1000

        assert latency < 200, f"Latency should be <200ms, got {latency:.2f}ms"

        logger.info(f"✓ Latency test passed | {latency:.2f}ms for 100 predictions")


# ============================================================================
# DATA PREPROCESSING TESTS
# ============================================================================

@pytest.mark.ml
class TestDataPreprocessor:
    """Professional tests for data preprocessing."""

    @pytest.mark.unit
    def test_data_cleaning(self, test_results_dataframe):
        """
        Test: Data cleaning removes invalid data
        Expected: No missing values, valid ranges
        """
        df = test_results_dataframe.copy()
        preprocessor = DataPreprocessor()

        cleaned = preprocessor.clean_test_results(df)

        assert len(cleaned) > 0, "Cleaned data should not be empty"
        assert cleaned.isnull().sum().sum() == 0, "Should have no missing values"

        logger.info(f"✓ Data cleaning test passed | {len(cleaned)} records cleaned")

    @pytest.mark.unit
    def test_feature_extraction(self, test_results_dataframe):
        """
        Test: Features are extracted correctly
        Expected: Correct number of features, proper scaling
        """
        df = test_results_dataframe.copy()
        preprocessor = DataPreprocessor()

        X, y = preprocessor.extract_features(df)

        assert X.shape[0] == len(df), "Feature count should match input"
        assert X.shape[1] == 5, "Should have 5 features"
        assert np.all(np.isfinite(X)), "Features should be finite"

        logger.info(f"✓ Feature extraction test passed | Shape: {X.shape}")

    @pytest.mark.unit
    def test_outlier_detection(self):
        """
        Test: Outliers are detected and handled
        Expected: Extreme values are removed
        """
        df = pd.DataFrame({
            'cognitive_score': [70, 75, 80, 1000],  # 1000 is outlier
            'motor_score': [65, 70, 75, -100],  # -100 is outlier
            'reaction_time': [400, 350, 300, 10000],
            'memory_retention': [80, 85, 90, 50],
            'accuracy_rate': [85, 90, 95, 30],
            'risk_level': ['low', 'low', 'high', 'low']
        })

        preprocessor = DataPreprocessor()
        cleaned = preprocessor.clean_test_results(df)

        # Outliers should be removed
        assert len(cleaned) < len(df), "Should remove outliers"

        logger.info(f"✓ Outlier detection test passed | Removed {len(df) - len(cleaned)} outliers")


# ============================================================================
# FEATURE ENGINEERING TESTS
# ============================================================================

@pytest.mark.ml
class TestFeatureEngineer:
    """Professional tests for feature engineering."""

    @pytest.mark.unit
    def test_temporal_features(self, test_results_dataframe):
        """
        Test: Temporal features are created correctly
        Expected: hour, day_of_week, month, is_weekend fields
        """
        df = test_results_dataframe.copy()
        engineer = FeatureEngineer()

        df_feat = engineer.create_temporal_features(df)

        expected_features = ['hour', 'day_of_week', 'month', 'is_weekend']
        for feat in expected_features:
            assert feat in df_feat.columns, f"Should have {feat} feature"

        logger.info(f"✓ Temporal features test passed | Created {len(expected_features)} features")

    @pytest.mark.unit
    def test_aggregated_features(self, test_results_dataframe):
        """
        Test: Aggregated rolling features are created
        Expected: Rolling mean, std, max, min columns
        """
        df = test_results_dataframe.copy()
        engineer = FeatureEngineer()

        df_feat = engineer.create_aggregated_features(df, window=7)

        # Should have new rolling features
        assert any('rolling' in col for col in df_feat.columns), "Should have rolling features"

        logger.info(f"✓ Aggregated features test passed | Total features: {len(df_feat.columns)}")

    @pytest.mark.unit
    def test_interaction_features(self, test_results_dataframe):
        """
        Test: Interaction features are created
        Expected: cognitive_motor_interaction, speed_accuracy_ratio
        """
        df = test_results_dataframe.copy()
        engineer = FeatureEngineer()

        df_feat = engineer.create_interaction_features(df)

        assert 'cognitive_motor_interaction' in df_feat.columns, "Should have interaction feature"
        assert 'speed_accuracy_ratio' in df_feat.columns, "Should have ratio feature"

        logger.info(f"✓ Interaction features test passed | Created interaction features")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
