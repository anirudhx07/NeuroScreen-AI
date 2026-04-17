"""
Professional Test Suite for ML Preprocessing and Training Pipeline.
Comprehensive testing of data validation, feature engineering, and model training workflows.

Author: NeuroScreen AI
Date: 2024-01-15
Version: 1.0.0
"""

import pytest
import numpy as np
import pandas as pd
import tempfile
import logging
from typing import Tuple
from datetime import datetime, timedelta

from ml.preprocessing import DataPreprocessor, FeatureEngineer, DataValidator
from ml.training import TrainingPipeline

logger = logging.getLogger(__name__)


# ============================================================================
# DATA VALIDATOR TESTS
# ============================================================================

@pytest.mark.ml
class TestDataValidator:
    """Professional tests for data validation."""

    @pytest.mark.unit
    def test_validate_valid_test_result(self):
        """
        Test: Validates correct test result
        Expected: Returns True with no errors
        """
        validator = DataValidator()
        test_result = {
            'user_id': 'user_123',
            'test_type': 'memory',
            'score': 75.5,
            'timestamp': '2024-01-15T10:00:00Z'
        }

        is_valid, errors = validator.validate_test_result(test_result)

        assert is_valid is True, "Valid result should pass"
        assert len(errors) == 0, "Should have no errors"
        logger.info("✓ Valid test result validation passed")

    @pytest.mark.unit
    def test_validate_missing_fields(self):
        """
        Test: Validates result with missing required fields
        Expected: Returns False with error messages
        """
        validator = DataValidator()
        test_result = {
            'user_id': 'user_123',
            # Missing test_type, score, timestamp
        }

        is_valid, errors = validator.validate_test_result(test_result)

        assert is_valid is False, "Invalid result should fail"
        assert len(errors) > 0, "Should have errors"
        logger.info(f"✓ Missing fields validation passed | Errors: {len(errors)}")

    @pytest.mark.unit
    def test_validate_invalid_score_range(self):
        """
        Test: Validates score outside valid range
        Expected: Returns False with score error
        """
        validator = DataValidator()
        test_result = {
            'user_id': 'user_123',
            'test_type': 'memory',
            'score': 150,  # Invalid: >100
            'timestamp': '2024-01-15T10:00:00Z'
        }

        is_valid, errors = validator.validate_test_result(test_result)

        assert is_valid is False, "Out-of-range score should fail"
        assert any('score' in str(e).lower() for e in errors), "Should mention score error"
        logger.info("✓ Invalid score range validation passed")

    @pytest.mark.unit
    def test_validate_dataset(self, test_results_dataframe):
        """
        Test: Validates entire dataset
        Expected: Comprehensive validation report
        """
        validator = DataValidator()
        is_valid, report = validator.validate_dataset(test_results_dataframe)

        assert 'total_rows' in report, "Report should have total_rows"
        assert 'missing_values' in report, "Report should have missing_values"
        assert 'duplicate_rows' in report, "Report should have duplicate_rows"
        assert 'issues' in report, "Report should have issues list"

        logger.info(f"✓ Dataset validation passed | Total rows: {report['total_rows']}")

    @pytest.mark.unit
    def test_validate_dataset_with_issues(self):
        """
        Test: Detects issues in dataset
        Expected: Reports all data quality issues
        """
        validator = DataValidator()

        df = pd.DataFrame({
            'cognitive_score': [70, np.nan, 80],  # Missing value
            'motor_score': [65, 70, 65],  # Duplicate row
            'reaction_time': [400, 350, 400],
            'memory_retention': [80, 85, 80],
            'accuracy_rate': [85, 90, 85]
        })

        is_valid, report = validator.validate_dataset(df)

        assert not is_valid or len(report['issues']) > 0, "Should detect issues"
        logger.info(f"✓ Issue detection passed | Issues: {len(report['issues'])}")


# ============================================================================
# DATA PREPROCESSOR TESTS
# ============================================================================

@pytest.mark.ml
class TestDataPreprocessor:
    """Professional tests for data preprocessing."""

    @pytest.mark.unit
    def test_clean_removes_duplicates(self):
        """
        Test: Cleaning removes duplicate rows
        Expected: Duplicate rows are removed
        """
        preprocessor = DataPreprocessor()

        df = pd.DataFrame({
            'cognitive_score': [70, 75, 70],  # Row 0 and 2 are duplicates
            'motor_score': [65, 70, 65],
            'reaction_time': [400, 350, 400],
            'memory_retention': [80, 85, 80],
            'accuracy_rate': [85, 90, 85]
        })

        cleaned = preprocessor.clean_test_results(df)

        assert len(cleaned) < len(df), "Should remove duplicates"
        logger.info(f"✓ Duplicate removal test passed | {len(df) - len(cleaned)} duplicates removed")

    @pytest.mark.unit
    def test_clean_handles_missing_values(self):
        """
        Test: Cleaning handles missing values
        Expected: Missing values are filled or rows removed
        """
        preprocessor = DataPreprocessor()

        df = pd.DataFrame({
            'cognitive_score': [70, np.nan, 80],
            'motor_score': [65, 70, 75],
            'reaction_time': [400, 350, 300],
            'memory_retention': [80, 85, 90],
            'accuracy_rate': [85, 90, 95]
        })

        cleaned = preprocessor.clean_test_results(df)

        assert cleaned.isnull().sum().sum() == 0, "Should have no missing values"
        logger.info("✓ Missing values handling test passed")

    @pytest.mark.unit
    def test_clean_removes_outliers(self):
        """
        Test: Cleaning removes extreme outliers
        Expected: Out-of-range values are removed
        """
        preprocessor = DataPreprocessor()

        df = pd.DataFrame({
            'cognitive_score': [70, 75, 80, 500],  # 500 is outlier
            'motor_score': [65, 70, 75, 50],
            'reaction_time': [400, 350, 300, 10000],  # 10000 is outlier
            'memory_retention': [80, 85, 90, 50],
            'accuracy_rate': [85, 90, 95, 30]
        })

        cleaned = preprocessor.clean_test_results(df)

        assert len(cleaned) < len(df), "Should remove outliers"
        logger.info(f"✓ Outlier removal test passed | {len(df) - len(cleaned)} outliers removed")

    @pytest.mark.unit
    def test_extract_features_shape(self, test_results_dataframe):
        """
        Test: Features extracted with correct shape
        Expected: X has shape (n_samples, 5), y has n_samples
        """
        preprocessor = DataPreprocessor()
        X, y = preprocessor.extract_features(test_results_dataframe)

        assert X.shape[0] == len(test_results_dataframe), "Sample count should match"
        assert X.shape[1] == 5, "Should have 5 features"
        assert np.all(np.isfinite(X)), "All features should be finite"

        logger.info(f"✓ Feature extraction shape test passed | Shape: {X.shape}")

    @pytest.mark.unit
    def test_extract_features_normalized(self, test_results_dataframe):
        """
        Test: Extracted features are normalized
        Expected: Features have mean~0, std~1
        """
        preprocessor = DataPreprocessor()
        X, y = preprocessor.extract_features(test_results_dataframe)

        # Check normalization
        means = np.mean(X, axis=0)
        stds = np.std(X, axis=0)

        assert np.allclose(means, 0, atol=1), "Features should have mean~0"
        assert np.allclose(stds, 1, atol=0.5), "Features should have std~1"

        logger.info(f"✓ Feature normalization test passed | Means: {means}, Stds: {stds}")


# ============================================================================
# FEATURE ENGINEER TESTS
# ============================================================================

@pytest.mark.ml
class TestFeatureEngineer:
    """Professional tests for feature engineering."""

    @pytest.mark.unit
    def test_temporal_features_created(self, test_results_dataframe):
        """
        Test: Temporal features are created
        Expected: hour, day_of_week, month, is_weekend columns added
        """
        engineer = FeatureEngineer()
        df_with_features = engineer.create_temporal_features(test_results_dataframe.copy())

        expected_features = ['hour', 'day_of_week', 'month', 'is_weekend']
        for feat in expected_features:
            assert feat in df_with_features.columns, f"Should have {feat} feature"

        logger.info(f"✓ Temporal features test passed | Created {len(expected_features)} features")

    @pytest.mark.unit
    def test_temporal_features_values_valid(self):
        """
        Test: Temporal features have valid values
        Expected: Values in expected ranges
        """
        engineer = FeatureEngineer()
        df = pd.DataFrame({
            'timestamp': pd.date_range('2024-01-01', periods=10)
        })

        df = engineer.create_temporal_features(df)

        assert df['hour'].min() >= 0 and df['hour'].max() <= 23, "Hour should be 0-23"
        assert df['day_of_week'].min() >= 0 and df['day_of_week'].max() <= 6, "Day should be 0-6"
        assert df['month'].min() >= 1 and df['month'].max() <= 12, "Month should be 1-12"
        assert set(df['is_weekend'].unique()).issubset({0, 1}), "is_weekend should be 0 or 1"

        logger.info("✓ Temporal features values test passed")

    @pytest.mark.unit
    def test_aggregated_features_created(self, test_results_dataframe):
        """
        Test: Aggregated rolling features are created
        Expected: Rolling mean, std, max, min columns added
        """
        engineer = FeatureEngineer()
        df_with_features = engineer.create_aggregated_features(test_results_dataframe.copy(), window=7)

        rolling_cols = [col for col in df_with_features.columns if 'rolling' in col]
        assert len(rolling_cols) > 0, "Should have rolling features"

        logger.info(f"✓ Aggregated features test passed | Created {len(rolling_cols)} rolling features")

    @pytest.mark.unit
    def test_interaction_features_created(self, test_results_dataframe):
        """
        Test: Interaction features are created
        Expected: cognitive_motor_interaction and speed_accuracy_ratio
        """
        engineer = FeatureEngineer()
        df_with_features = engineer.create_interaction_features(test_results_dataframe.copy())

        assert 'cognitive_motor_interaction' in df_with_features.columns, "Should have interaction feature"
        assert 'speed_accuracy_ratio' in df_with_features.columns, "Should have ratio feature"

        logger.info("✓ Interaction features test passed")

    @pytest.mark.unit
    def test_normalize_features(self):
        """
        Test: Features normalization
        Expected: Normalized features have mean~0, std~1
        """
        engineer = FeatureEngineer()
        X = np.random.rand(100, 5) * 100  # Random 0-100

        X_normalized, scaler = engineer.normalize_features(X, method='standard')

        means = np.mean(X_normalized, axis=0)
        stds = np.std(X_normalized, axis=0)

        assert np.allclose(means, 0, atol=1), "Normalized features should have mean~0"
        assert np.allclose(stds, 1, atol=0.5), "Normalized features should have std~1"

        logger.info("✓ Feature normalization test passed")

    @pytest.mark.unit
    @pytest.mark.parametrize("method", ['standard', 'minmax'])
    def test_normalize_various_methods(self, method):
        """
        Test: Normalization with various methods
        Expected: Both methods work correctly
        """
        engineer = FeatureEngineer()
        X = np.random.rand(50, 5) * 100

        X_normalized, scaler = engineer.normalize_features(X, method=method)

        assert X_normalized.shape == X.shape, "Shape should be preserved"
        assert np.all(np.isfinite(X_normalized)), "All normalized values should be finite"

        logger.info(f"✓ Normalization with {method} method passed")


# ============================================================================
# TRAINING PIPELINE TESTS
# ============================================================================

@pytest.mark.ml
class TestTrainingPipeline:
    """Professional tests for training pipeline."""

    @pytest.mark.unit
    def test_pipeline_initialization(self):
        """
        Test: Pipeline initializes correctly
        Expected: All components initialized
        """
        pipeline = TrainingPipeline()

        assert pipeline.preprocessor is not None, "Should have preprocessor"
        assert pipeline.feature_engineer is not None, "Should have feature engineer"
        assert pipeline.validator is not None, "Should have validator"
        assert pipeline.risk_predictor is not None, "Should have risk predictor"
        assert pipeline.trend_analyzer is not None, "Should have trend analyzer"
        assert pipeline.anomaly_detector is not None, "Should have anomaly detector"

        logger.info("✓ Pipeline initialization test passed")

    @pytest.mark.unit
    def test_pipeline_data_loading(self):
        """
        Test: Pipeline can load data
        Expected: Data loaded with correct shape
        """
        pipeline = TrainingPipeline()
        df = pipeline.load_data("test_data_source")

        assert isinstance(df, pd.DataFrame), "Should return DataFrame"
        assert len(df) > 0, "Should have data"
        assert 'user_id' in df.columns, "Should have user_id"
        assert 'risk_level' in df.columns, "Should have risk_level"

        logger.info(f"✓ Data loading test passed | Shape: {df.shape}")

    @pytest.mark.integration
    def test_full_training_pipeline(self, tmp_path):
        """
        Test: Full training pipeline execution
        Expected: Models trained and saved successfully
        """
        pipeline = TrainingPipeline()
        output_dir = str(tmp_path)

        results = pipeline.run(
            data_source="test_data",
            output_dir=output_dir
        )

        assert 'risk_predictor_metrics' in results, "Should have risk predictor metrics"
        assert 'anomaly_detector_metrics' in results, "Should have anomaly metrics"
        assert 'training_history' in results, "Should have training history"

        logger.info(f"✓ Full training pipeline test passed | Results: {list(results.keys())}")

    @pytest.mark.unit
    def test_pipeline_config(self):
        """
        Test: Pipeline configuration
        Expected: Config settings applied correctly
        """
        config = {'batch_size': 64, 'max_workers': 8}
        pipeline = TrainingPipeline(config=config)

        assert pipeline.config == config, "Config should be stored"
        logger.info("✓ Pipeline configuration test passed")


# ============================================================================
# END-TO-END DATA PROCESSING TESTS
# ============================================================================

@pytest.mark.ml
class TestEndToEndProcessing:
    """End-to-end data processing tests."""

    @pytest.mark.integration
    def test_complete_preprocessing_workflow(self, test_results_dataframe):
        """
        Test: Complete preprocessing workflow
        Expected: Data flows through all preprocessing steps
        """
        logger.info("Starting complete preprocessing workflow test")

        preprocessor = DataPreprocessor()
        engineer = FeatureEngineer()

        # Step 1: Clean
        cleaned = preprocessor.clean_test_results(test_results_dataframe.copy())
        assert len(cleaned) > 0, "Cleaned data should not be empty"

        # Step 2: Add temporal features
        with_temporal = engineer.create_temporal_features(cleaned.copy())
        assert 'hour' in with_temporal.columns, "Should have temporal features"

        # Step 3: Add aggregated features
        with_agg = engineer.create_aggregated_features(with_temporal.copy())
        assert any('rolling' in col for col in with_agg.columns), "Should have aggregated features"

        # Step 4: Add interaction features
        final = engineer.create_interaction_features(with_agg.copy())
        assert 'cognitive_motor_interaction' in final.columns, "Should have interactions"

        logger.info("✓ Complete preprocessing workflow test passed")

    @pytest.mark.integration
    def test_preprocessing_pipeline_robustness(self):
        """
        Test: Preprocessing handles various data conditions
        Expected: Robust to edge cases
        """
        preprocessor = DataPreprocessor()

        test_cases = [
            {
                'name': 'normal_data',
                'df': pd.DataFrame({
                    'cognitive_score': [70, 75, 80],
                    'motor_score': [65, 70, 75],
                    'reaction_time': [400, 350, 300],
                    'memory_retention': [80, 85, 90],
                    'accuracy_rate': [85, 90, 95]
                })
            },
            {
                'name': 'with_duplicates',
                'df': pd.DataFrame({
                    'cognitive_score': [70, 70, 80],
                    'motor_score': [65, 65, 75],
                    'reaction_time': [400, 400, 300],
                    'memory_retention': [80, 80, 90],
                    'accuracy_rate': [85, 85, 95]
                })
            },
            {
                'name': 'with_missing_values',
                'df': pd.DataFrame({
                    'cognitive_score': [70, np.nan, 80],
                    'motor_score': [65, 70, 75],
                    'reaction_time': [400, 350, 300],
                    'memory_retention': [80, 85, 90],
                    'accuracy_rate': [85, 90, 95]
                })
            },
        ]

        for test_case in test_cases:
            cleaned = preprocessor.clean_test_results(test_case['df'].copy())
            assert len(cleaned) > 0, f"Should clean {test_case['name']}"
            logger.info(f"✓ Robustness test passed for {test_case['name']}")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])