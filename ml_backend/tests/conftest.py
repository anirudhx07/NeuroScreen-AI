"""
Shared test fixtures and configuration.
Provides reusable test data, database setup, and mock models.
"""

import pytest
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, Tuple
import logging

# Configure logging for tests
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


# ============================================================================
# FIXTURE: Sample Neurological Assessment Data
# ============================================================================

@pytest.fixture(scope="session")
def realistic_test_data() -> Tuple[np.ndarray, np.ndarray]:
    """
    Generate realistic neurological assessment data.

    Returns:
        Tuple[np.ndarray, np.ndarray]: Features and labels based on real assessment patterns
    """
    np.random.seed(42)

    n_samples = 500

    # Realistic cognitive/motor features with medical patterns
    cognitive_scores = np.random.normal(70, 15, n_samples)  # Mean 70, std 15
    motor_scores = np.random.normal(75, 12, n_samples)
    reaction_times = np.random.normal(450, 100, n_samples)  # in milliseconds
    memory_retention = np.random.normal(80, 10, n_samples)
    accuracy_rates = np.random.normal(85, 8, n_samples)

    # Clamp to realistic ranges
    cognitive_scores = np.clip(cognitive_scores, 0, 100)
    motor_scores = np.clip(motor_scores, 0, 100)
    reaction_times = np.clip(reaction_times, 200, 800)
    memory_retention = np.clip(memory_retention, 0, 100)
    accuracy_rates = np.clip(accuracy_rates, 0, 100)

    X = np.column_stack([
        cognitive_scores,
        motor_scores,
        reaction_times,
        memory_retention,
        accuracy_rates
    ])

    # Generate risk levels based on scoring logic
    risk_scores = (
        (100 - cognitive_scores) * 0.3 +
        (100 - motor_scores) * 0.25 +
        (reaction_times / 800) * 100 * 0.25 +
        (100 - memory_retention) * 0.2
    ) / 4

    y = np.where(
        risk_scores < 33,
        0,  # low
        np.where(risk_scores < 67, 1, 2)  # medium, high
    )

    logger.info(f"Generated realistic test data: {X.shape}")
    logger.info(f"Class distribution: {np.bincount(y)}")

    return X, y


@pytest.fixture(scope="session")
def unbalanced_test_data() -> Tuple[np.ndarray, np.ndarray]:
    """
    Generate imbalanced dataset (common in real neurological data).
    80% low-risk, 15% medium-risk, 5% high-risk
    """
    np.random.seed(42)
    n_total = 500

    # Low-risk samples (80%)
    n_low = 400
    X_low = np.random.normal([70, 75, 400, 80, 85], [15, 12, 100, 10, 8], (n_low, 5))
    y_low = np.zeros(n_low)

    # Medium-risk samples (15%)
    n_medium = 75
    X_medium = np.random.normal([50, 55, 550, 60, 70], [15, 12, 100, 10, 8], (n_medium, 5))
    y_medium = np.ones(n_medium)

    # High-risk samples (5%)
    n_high = 25
    X_high = np.random.normal([30, 35, 700, 40, 55], [15, 12, 100, 10, 8], (n_high, 5))
    y_high = np.full(n_high, 2)

    X = np.vstack([X_low, X_medium, X_high])
    y = np.hstack([y_low, y_medium, y_high])

    # Shuffle
    shuffle_idx = np.random.permutation(n_total)
    X = X[shuffle_idx]
    y = y[shuffle_idx]

    logger.info(f"Generated imbalanced data: {X.shape}")
    logger.info(f"Class distribution: {np.bincount(y.astype(int))}")

    return X, y


@pytest.fixture
def temporal_test_data() -> pd.DataFrame:
    """
    Generate time-series test data for trend analysis.

    Returns:
        pd.DataFrame: User test results over time
    """
    dates = pd.date_range('2024-01-01', periods=30, freq='D')

    # Simulate improvement trend
    base_score = 70
    scores = base_score + np.arange(30) * 0.5 + np.random.normal(0, 2, 30)
    scores = np.clip(scores, 0, 100)

    df = pd.DataFrame({
        'timestamp': dates,
        'user_id': ['user_123'] * 30,
        'test_type': ['memory'] * 30,
        'score': scores,
        'reaction_time': np.random.uniform(300, 600, 30),
        'accuracy': np.random.uniform(80, 100, 30),
    })

    logger.info(f"Generated temporal data: {len(df)} records")
    return df


@pytest.fixture
def anomalous_data() -> np.ndarray:
    """
    Generate data with known anomalies.

    Returns:
        np.ndarray: Data with 5% anomalous samples
    """
    np.random.seed(42)
    n_normal = 95
    n_anomaly = 5

    # Normal data
    X_normal = np.random.normal([70, 75, 400, 80, 85], [15, 12, 100, 10, 8], (n_normal, 5))

    # Anomalous data (extreme outliers)
    X_anomaly = np.random.uniform([10, 10, 100, 10, 10], [20, 20, 200, 20, 20], (n_anomaly, 5))

    X = np.vstack([X_normal, X_anomaly])

    # Shuffle
    shuffle_idx = np.random.permutation(n_normal + n_anomaly)
    X = X[shuffle_idx]

    logger.info(f"Generated anomalous data: {X.shape}")
    return X


@pytest.fixture
def edge_case_data() -> Dict[str, np.ndarray]:
    """
    Generate edge case datasets for robustness testing.

    Returns:
        Dict: Various edge cases
    """
    return {
        'single_sample': np.array([[70, 75, 400, 80, 85]]),
        'two_samples': np.array([[70, 75, 400, 80, 85], [75, 80, 350, 85, 90]]),
        'all_same': np.array([[70, 70, 70, 70, 70]] * 10),
        'extreme_values': np.array([[0, 0, 1000, 0, 0], [100, 100, 100, 100, 100]]),
        'nan_values': np.array([[70, np.nan, 400, 80, 85]]),
        'inf_values': np.array([[70, np.inf, 400, 80, 85]]),
    }


# ============================================================================
# FIXTURE: Mock Models and Services
# ============================================================================

@pytest.fixture
def mock_risk_predictor():
    """Create a mock risk predictor for testing."""
    from ml.models import RiskPredictor

    model = RiskPredictor()
    return model


@pytest.fixture
def mock_trend_analyzer():
    """Create a mock trend analyzer for testing."""
    from ml.ml.models import TrendAnalyzer

    analyzer = TrendAnalyzer()
    return analyzer


@pytest.fixture
def mock_anomaly_detector():
    """Create a mock anomaly detector for testing."""
    from ml.models import AnomalyDetector

    detector = AnomalyDetector()
    return detector


# ============================================================================
# FIXTURE: Test DataFrame with Medical Data
# ============================================================================

@pytest.fixture
def test_results_dataframe() -> pd.DataFrame:
    """
    Create comprehensive test results DataFrame.

    Returns:
        pd.DataFrame: Sample test results
    """
    df = pd.DataFrame({
        'user_id': ['user_' + str(i % 10) for i in range(100)],
        'test_type': ['memory'] * 50 + ['motor'] * 25 + ['reaction'] * 25,
        'cognitive_score': np.random.normal(70, 15, 100),
        'motor_score': np.random.normal(75, 12, 100),
        'reaction_time': np.random.normal(450, 100, 100),
        'memory_retention': np.random.normal(80, 10, 100),
        'accuracy_rate': np.random.normal(85, 8, 100),
        'timestamp': [datetime.now() - timedelta(days=i) for i in range(100)],
    })

    # Clip to realistic ranges
    df['cognitive_score'] = np.clip(df['cognitive_score'], 0, 100)
    df['motor_score'] = np.clip(df['motor_score'], 0, 100)
    df['reaction_time'] = np.clip(df['reaction_time'], 200, 800)
    df['memory_retention'] = np.clip(df['memory_retention'], 0, 100)
    df['accuracy_rate'] = np.clip(df['accuracy_rate'], 0, 100)

    return df


# ============================================================================
# FIXTURE: Performance Benchmarking
# ============================================================================

@pytest.fixture
def benchmark_data() -> Dict[str, np.ndarray]:
    """
    Generate large datasets for performance benchmarking.

    Returns:
        Dict: Various sized datasets for benchmarking
    """
    return {
        'small': np.random.rand(100, 5),
        'medium': np.random.rand(1000, 5),
        'large': np.random.rand(10000, 5),
        'xlarge': np.random.rand(100000, 5),
    }


# ============================================================================
# FIXTURE: Markers and Parametrization
# ============================================================================

def pytest_configure(config):
    """Register custom markers."""
    config.addinivalue_line("markers", "unit: Unit tests for individual components")
    config.addinivalue_line("markers", "integration: Integration tests for systems")
    config.addinivalue_line("markers", "slow: Slow running tests")
    config.addinivalue_line("markers", "ml: ML/model specific tests")
    config.addinivalue_line("markers", "api: API endpoint tests")
    config.addinivalue_line("markers", "db: Database tests")
    config.addinivalue_line("markers", "performance: Performance tests")
