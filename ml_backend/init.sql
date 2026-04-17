-- Create schema for ML backend
CREATE SCHEMA IF NOT EXISTS ml;

-- Users table
CREATE TABLE ml.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    age INTEGER,
    gender VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_firebase_uid ON ml.users(firebase_uid);
CREATE INDEX idx_users_email ON ml.users(email);

-- Test results table
CREATE TABLE ml.test_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES ml.users(id) ON DELETE CASCADE,
    test_type VARCHAR(50) NOT NULL,
    score NUMERIC(5, 2) NOT NULL,
    reaction_time NUMERIC(8, 2),
    accuracy NUMERIC(5, 2),
    timestamp TIMESTAMP NOT NULL,
    raw_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT score_range CHECK (score >= 0 AND score <= 100)
);

CREATE INDEX idx_test_results_user_id ON ml.test_results(user_id);
CREATE INDEX idx_test_results_timestamp ON ml.test_results(timestamp);
CREATE INDEX idx_test_results_test_type ON ml.test_results(test_type);

-- Predictions table
CREATE TABLE ml.predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_result_id UUID NOT NULL REFERENCES ml.test_results(id) ON DELETE CASCADE,
    model_version VARCHAR(50) NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    risk_score NUMERIC(5, 2) NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    confidence NUMERIC(3, 2) NOT NULL,
    recommendations JSONB,
    inference_time_ms NUMERIC(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT risk_score_range CHECK (risk_score >= 0 AND risk_score <= 100),
    CONSTRAINT confidence_range CHECK (confidence >= 0 AND confidence <= 1)
);

CREATE INDEX idx_predictions_test_result_id ON ml.predictions(test_result_id);
CREATE INDEX idx_predictions_model_version ON ml.predictions(model_version);
CREATE INDEX idx_predictions_created_at ON ml.predictions(created_at);

-- Trends table
CREATE TABLE ml.trends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES ml.users(id) ON DELETE CASCADE,
    metric_name VARCHAR(100) NOT NULL,
    trend_direction VARCHAR(20) NOT NULL,
    trend_strength NUMERIC(3, 2),
    slope NUMERIC(10, 6),
    forecast_period INTEGER,
    forecast_values NUMERIC[] NOT NULL,
    calculated_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_trends_user_id ON ml.trends(user_id);
CREATE INDEX idx_trends_calculated_at ON ml.trends(calculated_at);

-- Anomalies table
CREATE TABLE ml.anomalies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_result_id UUID NOT NULL REFERENCES ml.test_results(id) ON DELETE CASCADE,
    is_anomaly BOOLEAN NOT NULL,
    anomaly_score NUMERIC(3, 2),
    severity VARCHAR(20),
    affected_metrics JSONB,
    details JSONB,
    detected_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT anomaly_score_range CHECK (anomaly_score >= 0 AND anomaly_score <= 1)
);

CREATE INDEX idx_anomalies_test_result_id ON ml.anomalies(test_result_id);
CREATE INDEX idx_anomalies_is_anomaly ON ml.anomalies(is_anomaly);

-- Model performance metrics table
CREATE TABLE ml.model_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name VARCHAR(100) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    accuracy NUMERIC(3, 2),
    precision NUMERIC(3, 2),
    recall NUMERIC(3, 2),
    f1_score NUMERIC(3, 2),
    auc_roc NUMERIC(3, 2),
    confusion_matrix JSONB,
    training_samples INTEGER,
    test_samples INTEGER,
    training_duration_seconds NUMERIC(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_model_metrics_model_name ON ml.model_metrics(model_name);
CREATE INDEX idx_model_metrics_created_at ON ml.model_metrics(created_at);

-- API logs table
CREATE TABLE ml.api_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms NUMERIC(10, 2),
    user_id UUID REFERENCES ml.users(id) ON DELETE SET NULL,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_api_logs_created_at ON ml.api_logs(created_at);
CREATE INDEX idx_api_logs_endpoint ON ml.api_logs(endpoint);
CREATE INDEX idx_api_logs_status_code ON ml.api_logs(status_code);

-- Create views for analytics

-- User test summary
CREATE VIEW ml.user_test_summary AS
SELECT
    u.id,
    u.firebase_uid,
    COUNT(tr.id) as total_tests,
    AVG(tr.score) as avg_score,
    MAX(tr.timestamp) as last_test_date,
    (SELECT COUNT(*) FROM ml.predictions WHERE test_result_id IN (
        SELECT id FROM ml.test_results WHERE user_id = u.id
    )) as total_predictions
FROM ml.users u
LEFT JOIN ml.test_results tr ON u.id = tr.user_id
GROUP BY u.id, u.firebase_uid;

-- Model performance summary
CREATE VIEW ml.model_performance_summary AS
SELECT
    model_name,
    model_version,
    AVG(accuracy) as avg_accuracy,
    AVG(f1_score) as avg_f1,
    COUNT(*) as total_evaluations,
    MAX(created_at) as last_trained
FROM ml.model_metrics
GROUP BY model_name, model_version;

-- Grant permissions
GRANT USAGE ON SCHEMA ml TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ml TO postgres;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA ml TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA ml TO postgres;
