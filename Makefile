.PHONY: help install dev test lint format clean docker-build docker-up docker-down train deploy docs

help:
	@echo "NeuroScreen ML Backend - Development Commands"
	@echo "=============================================="
	@echo ""
	@echo "Installation:"
	@echo "  make install         Install dependencies"
	@echo "  make install-dev     Install dev dependencies"
	@echo ""
	@echo "Development:"
	@echo "  make dev             Run development server"
	@echo "  make shell           Open Python shell"
	@echo ""
	@echo "Testing & Quality:"
	@echo "  make test            Run tests"
	@echo "  make test-cov        Run tests with coverage"
	@echo "  make lint            Lint code"
	@echo "  make format          Format code"
	@echo "  make typecheck       Type checking"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build    Build Docker image"
	@echo "  make docker-up       Start services"
	@echo "  make docker-down     Stop services"
	@echo "  make docker-logs     View logs"
	@echo ""
	@echo "ML Pipeline:"
	@echo "  make train           Train models"
	@echo "  make evaluate        Evaluate models"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean           Clean temp files"
	@echo "  make docs            Generate documentation"

install:
	pip install -r ml_backend/requirements.txt

install-dev:
	pip install -r ml_backend/requirements.txt
	pip install pytest pytest-cov black flake8 mypy

dev:
	cd ml_backend && python main.py

shell:
	cd ml_backend && python -i -c "from ml import *; import pandas as pd; import numpy as np"

test:
	pytest ml_backend/tests/ -v

test-cov:
	pytest ml_backend/tests/ -v --cov=ml_backend --cov-report=html --cov-report=term

lint:
	flake8 ml_backend --max-line-length=120 --exclude=__pycache__

format:
	black ml_backend --line-length=120

typecheck:
	mypy ml_backend --ignore-missing-imports

docker-build:
	docker build -t neuroscreen-ml:latest ml_backend/

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f ml_backend

train:
	cd ml_backend && python -m ml.training

evaluate:
	@echo "Model evaluation..."

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true

docs:
	@echo "Documentation generated in docs/ folder"

.DEFAULT_GOAL := help
