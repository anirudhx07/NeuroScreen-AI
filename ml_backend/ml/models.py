"""
ML Models for neurological assessment prediction and analysis.
"""

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor, IsolationForest
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score, roc_auc_score
)
import joblib
from typing import Tuple, Dict, Any
import logging

logger = logging.getLogger(__name__)


class RiskPredictor:
    """Predicts neurological risk level based on test results."""

    def __init__(self, model_path: str = None):
        """Initialize risk predictor."""
        self.model = None
        self.scaler = None
        self.feature_names = [
            'cognitive_score', 'motor_score', 'reaction_time',
            'memory_retention', 'accuracy_rate'
        ]
        if model_path:
            self.load(model_path)

    def train(self, X: np.ndarray, y: np.ndarray) -> Dict[str, float]:
        """Train risk prediction model."""
        logger.info(f"Training RiskPredictor on {X.shape[0]} samples")

        # Normalize features
        self.scaler = StandardScaler()
        X_scaled = self.scaler.fit_transform(X)

        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X_scaled, y, test_size=0.2, random_state=42
        )

        # Train ensemble
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=42,
            n_jobs=-1
        )
        self.model.fit(X_train, y_train)

        # Evaluate
        y_pred = self.model.predict(X_test)
        metrics = {
            'accuracy': accuracy_score(y_test, y_pred),
            'precision': precision_score(y_test, y_pred, average='weighted', zero_division=0),
            'recall': recall_score(y_test, y_pred, average='weighted', zero_division=0),
            'f1': f1_score(y_test, y_pred, average='weighted', zero_division=0),
        }

        logger.info(f"RiskPredictor training complete. Accuracy: {metrics['accuracy']:.3f}")
        return metrics

    def predict(self, X: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """Predict risk level and probability."""
        if self.model is None:
            raise ValueError("Model not trained")

        X_scaled = self.scaler.transform(X)
        predictions = self.model.predict(X_scaled)
        probabilities = self.model.predict_proba(X_scaled).max(axis=1)

        return predictions, probabilities

    def save(self, path: str):
        """Save model to disk."""
        joblib.dump(self.model, f"{path}_model.pkl")
        joblib.dump(self.scaler, f"{path}_scaler.pkl")
        logger.info(f"RiskPredictor saved to {path}")

    def load(self, path: str):
        """Load model from disk."""
        self.model = joblib.load(f"{path}_model.pkl")
        self.scaler = joblib.load(f"{path}_scaler.pkl")
        logger.info(f"RiskPredictor loaded from {path}")


class TrendAnalyzer:
    """Analyzes trends in test results over time."""

    def __init__(self):
        """Initialize trend analyzer."""
        self.trend_model = None
        self.scaler = StandardScaler()

    def calculate_trend(self, scores: np.ndarray) -> Dict[str, Any]:
        """Calculate trend statistics."""
        if len(scores) < 2:
            return {
                'direction': 'insufficient_data',
                'strength': 0.0,
                'slope': 0.0
            }

        # Linear regression for trend
        x = np.arange(len(scores)).reshape(-1, 1)
        y = scores.reshape(-1, 1)

        # Simple linear regression
        X_with_ones = np.column_stack([np.ones(len(x)), x.flatten()])
        coeffs = np.linalg.lstsq(X_with_ones, y, rcond=None)[0]
        slope = coeffs[1][0]

        # Determine direction
        if slope > 0.1:
            direction = "up"
        elif slope < -0.1:
            direction = "down"
        else:
            direction = "stable"

        # Calculate strength (0-1)
        strength = min(abs(slope) / 0.5, 1.0)  # More sensitive to small trends

        return {
            'direction': direction,
            'strength': strength,
            'slope': float(slope),
            'avg_score': float(np.mean(scores)),
            'std_score': float(np.std(scores))
        }

    def forecast(self, scores: np.ndarray, periods: int = 3) -> np.ndarray:
        """Forecast future scores."""
        if len(scores) < 2:
            return np.full(periods, scores[-1])

        # Calculate trend from historical data
        x = np.arange(len(scores)).reshape(-1, 1)
        y = scores.reshape(-1, 1)
        X_with_ones = np.column_stack([np.ones(len(x)), x.flatten()])
        coeffs = np.linalg.lstsq(X_with_ones, y, rcond=None)[0]
        slope = coeffs[1][0]

        # Forecast with trend continuation
        forecast = []
        for i in range(1, periods + 1):
            forecast_value = scores[-1] + (slope * i)
            forecast.append(forecast_value)

        return np.array(forecast)


class AnomalyDetector:
    """Detects anomalies in test result patterns."""

    def __init__(self):
        """Initialize anomaly detector."""
        self.model = None

    def train(self, X: np.ndarray) -> Dict[str, float]:
        """Train anomaly detection model."""
        logger.info(f"Training AnomalyDetector on {X.shape[0]} samples")

        self.model = IsolationForest(
            contamination=0.1,
            random_state=42,
            n_jobs=-1
        )
        self.model.fit(X)

        logger.info("AnomalyDetector training complete")
        return {'status': 'trained'}

    def predict(self, X: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """Detect anomalies."""
        if self.model is None:
            raise ValueError("Model not trained")

        # -1 for anomaly, 1 for normal
        predictions = self.model.predict(X)
        scores = self.model.score_samples(X)

        return predictions, scores

    def save(self, path: str):
        """Save model."""
        joblib.dump(self.model, f"{path}_model.pkl")

    def load(self, path: str):
        """Load model."""
        self.model = joblib.load(f"{path}_model.pkl")
