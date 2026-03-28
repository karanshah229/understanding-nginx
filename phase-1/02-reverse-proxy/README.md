# 🧪 Experiment 2 — Reverse Proxy & Admission Control

## 🏛️ Architecture
- **Proxy**: NGINX (Testing with and without limits).
- **Backends**: Spring Boot (Thread-per-request) and Fastify (Node.js).
- **Load Tool**: `autocannon`.

## ⚙️ Setup

### Prerequisites
- Docker & Docker Compose.
- `host.docker.internal` should be resolvable.

### Directory Structure
```text
.
├── 001-java-backend/        # Fast Java (Thread-per-request)
├── 002-node-backend/        # Fast Node.js (Event Loop)
├── 003-slow-java-backend/   # Slow Java (with Rate Limiting)
├── experiment.md           # Scientific journal style guide
├── README.md               # Operational guide
└── insights.md             # Unified architectural observations
```

## 🚀 Execution Guide

### Phase 2.1: Java (Blocking I/O)
```bash
cd 001-java-backend
docker compose up --build
# Compare direct vs. proxy performance
npx autocannon -c 50 -d 30 http://localhost:8081/
npx autocannon -c 50 -d 30 http://localhost:8080/
```

### Phase 2.2: Node.js (Non-Blocking I/O)
```bash
cd 002-node-backend
docker compose up --build
# Observe queue amplification under high concurrency
npx autocannon -c 10000 -d 30 http://localhost:8080/
```

### Phase 2.3: Slow Backend & Protection
```bash
cd 003-slow-java-backend
docker compose up --build
# Observe effect of rate limiting and limit_conn
npx autocannon -c 1000 -d 30 http://localhost:8080/
```

## 📊 Observations
See [insights.md](file:///Users/karan/projects/Personal_projects/understanding-nginx/phase-1/02-reverse-proxy/insights.md) for a detailed breakdown of the latency, throughput, and CPU behaviors across all three scenarios.
