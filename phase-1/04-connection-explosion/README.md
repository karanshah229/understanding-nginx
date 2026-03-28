# 🧪 Experiment 4 — Operating Guide

> [!NOTE]
> For the core hypothesis and architectural goals, see [experiment.md](file:///Users/karan/projects/Personal_projects/understanding-nginx/phase-1/04-connection-explosion/experiment.md).

## 🏛️ Architecture
- **Proxy**: NGINX (1 Master + 6 Workers).
- **Network**: Private Docker bridge (`connection-net`).
- **Clients**: 4 × Node.js `autocannon` containers.

## ⚙️ Setup

### Prerequisites
- Docker & Docker Compose
- `ulimit -n` host-level configuration (recommended: 200k+).

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
├── load-test/
│   └── Dockerfile
├── observations/
│   └── (Captured data logs)
└── scripts/
    ├── measure-fd.sh
    ├── measure-threads.sh
    └── watch.sh
```

## 🚀 Execution Guide

### 1. Build and Start the Infrastructure
```bash
docker compose up --build -d nginx
```

### 2. Monitor Metrics (Target Terminal)
Open a dedicated terminal and run:
```bash
chmod +x scripts/*.sh
./scripts/watch.sh
```

### 3. Run the Scale Progression
#### Step A: 1,000 Connections
```bash
docker compose run client-1 -c 1000 -d 30 http://nginx:8080/
```

#### Step B: 10,000 Connections
```bash
docker compose run client-1 -c 10000 -d 30 http://nginx:8080/
```

#### Step C: 100,000 Connections (Burst)
```bash
docker compose up client-1 client-2 client-3 client-4
```

## 📊 Observations
See [insights.md](file:///Users/karan/projects/Personal_projects/understanding-nginx/phase-1/04-connection-explosion/insights.md) for a detailed breakdown of the 1k → 100k scaling performance.
