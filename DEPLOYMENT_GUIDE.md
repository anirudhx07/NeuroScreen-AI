# Deployment Guides

## 1. Local Development Setup

### Prerequisites
- Python 3.11+
- Docker & Docker Compose
- Git

### Steps

```bash
# 1. Clone and setup
git clone <repo>
cd NeuroScreen-AI

# 2. Create Python environment
python -m venv venv
source venv/bin/activate

# 3. Install dependencies
make install-dev

# 4. Start local services
docker-compose up -d

# 5. Run migrations
cd ml_backend
alembic upgrade head

# 6. Start API
make dev
```

## 2. Docker Deployment

### Build & Run

```bash
# Build image
make docker-build

# Start all services
make docker-up

# View logs
make docker-logs

# Stop services
make docker-down
```

### Accessing Services
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Database UI: http://localhost:8080
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000

## 3. Production Deployment

### AWS Deployment

#### Prerequisites
- AWS Account
- AWS CLI configured
- ECR registry
- ECS cluster

#### Steps

```bash
# 1. Build and push Docker image
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

docker build -t neuroscreen-ml:latest ml_backend/
docker tag neuroscreen-ml:latest <account>.dkr.ecr.us-east-1.amazonaws.com/neuroscreen-ml:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/neuroscreen-ml:latest

# 2. Update ECS service
aws ecs update-service \
  --cluster neuroscreen-prod \
  --service neuroscreen-ml \
  --force-new-deployment

# 3. Monitor deployment
aws ecs describe-services \
  --cluster neuroscreen-prod \
  --services neuroscreen-ml
```

### Google Cloud Deployment

#### Prerequisites
- Google Cloud Project
- Cloud Run enabled
- Cloud SQL PostgreSQL

#### Steps

```bash
# 1. Build and push image
gcloud builds submit --tag gcr.io/<project>/neuroscreen-ml ml_backend/

# 2. Deploy to Cloud Run
gcloud run deploy neuroscreen-ml \
  --image gcr.io/<project>/neuroscreen-ml:latest \
  --platform managed \
  --region us-central1 \
  --memory 2Gi \
  --cpu 2 \
  --set-env-vars DATABASE_URL=$DATABASE_URL

# 3. View logs
gcloud logging read "resource.type=cloud_run_revision" -n 50
```

### Kubernetes Deployment

#### Prerequisites
- Kubernetes cluster
- kubectl configured
- Helm (optional)

#### Steps

```bash
# 1. Create namespace
kubectl create namespace neuroscreen

# 2. Create secrets
kubectl create secret generic ml-backend-secrets \
  --from-literal=DATABASE_URL=$DATABASE_URL \
  --from-literal=FIREBASE_CREDENTIALS=$FIREBASE_CREDS \
  -n neuroscreen

# 3. Deploy
kubectl apply -f k8s/ -n neuroscreen

# 4. Verify deployment
kubectl get pods -n neuroscreen
kubectl logs -f deployment/neuroscreen-ml -n neuroscreen
```

## 4. Database Migration

### Before Deployment

```bash
# 1. Backup current database
pg_dump -U postgres neuroscreen_ml > backup_$(date +%Y%m%d).sql

# 2. Run migrations
alembic upgrade head

# 3. Verify migration
alembic current
```

### Rollback

```bash
# If migration fails
alembic downgrade -1
```

## 5. Monitoring & Logging

### Prometheus Setup

```bash
# Access Prometheus
http://localhost:9090

# Query metrics
# - request_duration_seconds
# - model_inference_duration_seconds
# - database_query_duration_seconds
```

### Grafana Dashboards

```bash
# Access Grafana
http://localhost:3000
# Login: admin/admin

# Create dashboards for:
# - API Performance
# - Model Inference Times
# - Database Metrics
# - System Resources
```

### CloudWatch Logs (AWS)

```bash
# View logs
aws logs tail /aws/ecs/neuroscreen-ml --follow
```

## 6. Performance Tuning

### Database
```sql
-- Create indexes
CREATE INDEX idx_test_results_user_id ON test_results(user_id);
CREATE INDEX idx_test_results_timestamp ON test_results(timestamp);
CREATE INDEX idx_predictions_model ON predictions(model_version);

-- Enable query optimization
ANALYZE;
```

### Application
```bash
# Adjust worker count
gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker

# Enable caching
export REDIS_URL=redis://localhost:6379/0
```

## 7. Backup & Recovery

### Automated Backups

```bash
# Daily backup script
0 2 * * * pg_dump -U postgres neuroscreen_ml | gzip > /backups/db_$(date +\%Y\%m\%d).sql.gz
```

### Restore from Backup

```bash
# Restore database
gunzip < backup_20240115.sql.gz | psql -U postgres neuroscreen_ml
```

## 8. Scaling

### Horizontal Scaling

```bash
# Add more API instances
kubectl scale deployment neuroscreen-ml --replicas=5 -n neuroscreen
```

### Vertical Scaling

```bash
# Increase resources per instance
kubectl set resources deployment neuroscreen-ml \
  --limits=cpu=2,memory=4Gi \
  --requests=cpu=1,memory=2Gi \
  -n neuroscreen
```

## 9. Security Hardening

### Environment Variables
```bash
# Never commit secrets
# Use .env files locally
# Use secret managers in production (AWS Secrets Manager, Google Cloud Secret Manager)
```

### TLS/SSL
```bash
# Enable HTTPS
# Use Let's Encrypt certificates
# Configure in load balancer
```

### API Security
```bash
# Rate limiting
# CORS configuration
# API key rotation
```

## 10. Troubleshooting

### Common Issues

**Connection Refused**
```bash
# Check if service is running
docker-compose ps

# Check logs
docker-compose logs ml_backend
```

**Out of Memory**
```bash
# Increase memory limit
docker update --memory 4g <container-id>
```

**Database Lock**
```bash
# Kill hanging connections
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle';
```

---

**Last Updated**: 2024-01-15
