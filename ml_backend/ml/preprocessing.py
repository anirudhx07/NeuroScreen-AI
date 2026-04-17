"""
Data preprocessing and feature engineering for ML pipeline.
"""

import numpy as np
import pandas as pd
from typing import Tuple, Dict, List
from sklearn.preprocessing import StandardScaler, MinMaxScaler
import logging

logger = logging.getLogger(__name__)


class DataPreprocessor:
    """Handles data preprocessing and cleaning."""

    @staticmethod
    def clean_test_results(df: pd.DataFrame) -> pd.DataFrame:
        """Clean and validate test results."""
        logger.info(f"Cleaning {len(df)} test results")

        # Remove duplicates
        df = df.drop_duplicates()

        # Handle missing values
        df = df.fillna(method='ffill')

        # Remove outliers (beyond 3 standard deviations)
        numeric_cols = df.select_dtypes(include=[np.number]).columns
        for col in numeric_cols:
            mean = df[col].mean()
            std = df[col].std()
            df = df[
                (df[col] >= mean - 3 * std) & (df[col] <= mean + 3 * std)
            ]

        logger.info(f"Cleaned data shape: {df.shape}")
        return df

    @staticmethod
    def extract_features(df: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray]:
        """Extract features from test results."""
        logger.info("Extracting features")

        feature_columns = [
            'cognitive_score', 'motor_score', 'reaction_time',
            'memory_retention', 'accuracy_rate'
        ]

        # Select features
        X = df[feature_columns].values

        # Normalize
        scaler = StandardScaler()
        X_scaled = scaler.fit_transform(X)

        # Get labels (risk level)
        y = df['risk_level'].values if 'risk_level' in df.columns else None

        logger.info(f"Features extracted: shape {X_scaled.shape}")
        return X_scaled, y


class FeatureEngineer:
    """Advanced feature engineering."""

    @staticmethod
    def create_temporal_features(df: pd.DataFrame) -> pd.DataFrame:
        """Create time-based features."""
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df['hour'] = df['timestamp'].dt.hour
        df['day_of_week'] = df['timestamp'].dt.dayofweek
        df['month'] = df['timestamp'].dt.month
        df['is_weekend'] = df['day_of_week'].isin([5, 6]).astype(int)

        return df

    @staticmethod
    def create_aggregated_features(df: pd.DataFrame, window: int = 7) -> pd.DataFrame:
        """Create aggregated rolling features."""
        numeric_cols = df.select_dtypes(include=[np.number]).columns

        for col in numeric_cols:
            df[f'{col}_rolling_mean'] = df[col].rolling(window=window).mean()
            df[f'{col}_rolling_std'] = df[col].rolling(window=window).std()
            df[f'{col}_rolling_max'] = df[col].rolling(window=window).max()
            df[f'{col}_rolling_min'] = df[col].rolling(window=window).min()

        return df

    @staticmethod
    def create_interaction_features(df: pd.DataFrame) -> pd.DataFrame:
        """Create interaction features."""
        if 'cognitive_score' in df.columns and 'motor_score' in df.columns:
            df['cognitive_motor_interaction'] = (
                df['cognitive_score'] * df['motor_score']
            )

        if 'reaction_time' in df.columns and 'accuracy_rate' in df.columns:
            df['speed_accuracy_ratio'] = (
                df['reaction_time'] / (df['accuracy_rate'] + 1)
            )

        return df

    @staticmethod
    def normalize_features(
        X: np.ndarray,
        method: str = 'standard'
    ) -> Tuple[np.ndarray, Any]:
        """Normalize features."""
        if method == 'standard':
            scaler = StandardScaler()
        elif method == 'minmax':
            scaler = MinMaxScaler()
        else:
            raise ValueError(f"Unknown normalization method: {method}")

        X_normalized = scaler.fit_transform(X)
        return X_normalized, scaler


class DataValidator:
    """Validates data quality and integrity."""

    @staticmethod
    def validate_test_result(test_result: Dict) -> Tuple[bool, List[str]]:
        """Validate individual test result."""
        errors = []

        # Check required fields
        required_fields = ['user_id', 'test_type', 'score', 'timestamp']
        for field in required_fields:
            if field not in test_result:
                errors.append(f"Missing required field: {field}")

        # Validate score range
        if 'score' in test_result:
            score = test_result['score']
            if not (0 <= score <= 100):
                errors.append(f"Score out of range: {score}")

        # Validate timestamp
        if 'timestamp' in test_result:
            try:
                pd.to_datetime(test_result['timestamp'])
            except:
                errors.append("Invalid timestamp format")

        return len(errors) == 0, errors

    @staticmethod
    def validate_dataset(df: pd.DataFrame) -> Tuple[bool, Dict]:
        """Validate entire dataset."""
        report = {
            'total_rows': len(df),
            'missing_values': df.isnull().sum().to_dict(),
            'duplicate_rows': df.duplicated().sum(),
            'dtypes': df.dtypes.to_dict(),
            'issues': []
        }

        # Check for missing values
        missing = df.isnull().sum()
        if missing.any():
            report['issues'].append(f"Found {missing.sum()} missing values")

        # Check for duplicates
        if df.duplicated().any():
            report['issues'].append(f"Found {df.duplicated().sum()} duplicate rows")

        is_valid = len(report['issues']) == 0

        return is_valid, report
