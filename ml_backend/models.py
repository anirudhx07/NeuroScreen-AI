"""
Database models and ORM definitions.
"""

from sqlalchemy import (
    Column, String, Integer, Float, DateTime, Boolean, JSON, ARRAY,
    ForeignKey, Text, Numeric
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

Base = declarative_base()


class User(Base):
    """User model."""
    __tablename__ = "users"
    __table_args__ = {'schema': 'ml'}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    firebase_uid = Column(String(255), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    name = Column(String(255))
    age = Column(Integer)
    gender = Column(String(50))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    test_results = relationship("TestResult", back_populates="user")
    trends = relationship("Trend", back_populates="user")


class TestResult(Base):
    """Test result model."""
    __tablename__ = "test_results"
    __table_args__ = {'schema': 'ml'}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey('ml.users.id'), nullable=False)
    test_type = Column(String(50), nullable=False)
    score = Column(Numeric(5, 2), nullable=False)
    reaction_time = Column(Numeric(8, 2))
    accuracy = Column(Numeric(5, 2))
    timestamp = Column(DateTime, nullable=False)
    raw_data = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="test_results")
    predictions = relationship("Prediction", back_populates="test_result")
    anomalies = relationship("Anomaly", back_populates="test_result")


class Prediction(Base):
    """Prediction model."""
    __tablename__ = "predictions"
    __table_args__ = {'schema': 'ml'}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    test_result_id = Column(UUID(as_uuid=True), ForeignKey('ml.test_results.id'), nullable=False)
    model_version = Column(String(50), nullable=False)
    model_name = Column(String(100), nullable=False)
    risk_score = Column(Numeric(5, 2), nullable=False)
    risk_level = Column(String(20), nullable=False)
    confidence = Column(Numeric(3, 2), nullable=False)
    recommendations = Column(JSON)
    inference_time_ms = Column(Numeric(10, 2))
    created_at = Column(DateTime, default=datetime.utcnow)

    test_result = relationship("TestResult", back_populates="predictions")


class Trend(Base):
    """Trend model."""
    __tablename__ = "trends"
    __table_args__ = {'schema': 'ml'}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey('ml.users.id'), nullable=False)
    metric_name = Column(String(100), nullable=False)
    trend_direction = Column(String(20), nullable=False)
    trend_strength = Column(Numeric(3, 2))
    slope = Column(Numeric(10, 6))
    forecast_period = Column(Integer)
    forecast_values = Column(ARRAY(Float))
    calculated_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="trends")


class Anomaly(Base):
    """Anomaly model."""
    __tablename__ = "anomalies"
    __table_args__ = {'schema': 'ml'}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    test_result_id = Column(UUID(as_uuid=True), ForeignKey('ml.test_results.id'), nullable=False)
    is_anomaly = Column(Boolean, nullable=False)
    anomaly_score = Column(Numeric(3, 2))
    severity = Column(String(20))
    affected_metrics = Column(JSON)
    details = Column(JSON)
    detected_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    test_result = relationship("TestResult", back_populates="anomalies")


class ModelMetrics(Base):
    """Model performance metrics."""
    __tablename__ = "model_metrics"
    __table_args__ = {'schema': 'ml'}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    model_name = Column(String(100), nullable=False)
    model_version = Column(String(50), nullable=False)
    accuracy = Column(Numeric(3, 2))
    precision = Column(Numeric(3, 2))
    recall = Column(Numeric(3, 2))
    f1_score = Column(Numeric(3, 2))
    auc_roc = Column(Numeric(3, 2))
    confusion_matrix = Column(JSON)
    training_samples = Column(Integer)
    test_samples = Column(Integer)
    training_duration_seconds = Column(Numeric(10, 2))
    created_at = Column(DateTime, default=datetime.utcnow)


class APILog(Base):
    """API request logs."""
    __tablename__ = "api_logs"
    __table_args__ = {'schema': 'ml'}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    endpoint = Column(String(255), nullable=False)
    method = Column(String(10), nullable=False)
    status_code = Column(Integer, nullable=False)
    response_time_ms = Column(Numeric(10, 2))
    user_id = Column(UUID(as_uuid=True), ForeignKey('ml.users.id'))
    error_message = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
