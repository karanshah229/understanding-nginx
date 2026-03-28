# 🧪 Experiment 5 — Operating Guide

> [!NOTE]
> For the core hypothesis and architectural goals, see [experiment.md](file:///Users/karan/projects/Personal_projects/understanding-nginx/phase-1/05-traffic-spike/experiment.md).

## 🏛️ Architecture
- **Client**: `autocannon` (sending 200 concurrent requests).
- **Proxy**: NGINX (minimal proxy pass).
- **Backend (Spring Boot)**: Max **20 threads**, sleep **50-200ms**.

## ⚙️ Setup

### Prerequisites
- Docker & Docker Compose
- Node.js (for `npx autocannon`)

### Directory Structure
```text
.
├── compose.yml
├── experiment.md
├── README.md
├── insights.md
├── nginx/
│   ├── nginx.conf
│   └── Dockerfile
├── backend/
│   ├── src/main/java/com/example/App.java
│   ├── pom.xml
│   └── Dockerfile
└── scripts/
    └── benchmark.sh
```

## 🚀 Execution Guide

### 1. Build and Start the System
```bash
docker compose up --build
```

### 2. Monitor Metrics (Second Terminal)
```bash
docker stats
```

### 3. Run the Traffic Spike (Third Terminal)
```bash
chmod +x scripts/benchmark.sh
./scripts/benchmark.sh
```

## 📊 Observations
Fill in your findings in [insights.md](file:///Users/karan/projects/Personal_projects/understanding-nginx/phase-1/05-traffic-spike/insights.md) after running the benchmark.
