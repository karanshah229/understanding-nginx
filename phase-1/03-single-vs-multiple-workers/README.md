# 🧪 Experiment 3 — Operating Guide

> [!NOTE]
> For the core hypothesis and architectural goals, see [experiment.md](file:///Users/karan/projects/Personal_projects/understanding-nginx/phase-1/03-single-vs-multiple-workers/experiment.md).

## 🏛️ Architecture
- **Proxy**: NGINX (Testing 1 vs. N Workers).
- **Backend**: Spring Boot (running on `host.docker.internal:8081`).
- **Load Tool**: `autocannon` or `wrk`.

## ⚙️ Setup

### Prerequisites
- Docker & NGINX.
- A running backend service on port 8081.

### Directory Structure
```text
.
├── experiment.md
├── README.md
├── insights.md
├── nginx/
│   ├── nginx.conf
│   └── Dockerfile
├── backend/
│   └── (Spring Boot source)
└── observations/
    ├── small_load/
    └── large_load/
```

## 🚀 Execution Guide

### 1. Build and Start NGINX
```bash
docker build -t nginx-workers ./nginx
docker run --name nginx-workers -p 8080:8080 nginx-workers
```

### 2. Monitor CPU Distribution (Target Terminal)
Open a dedicated terminal and run:
```bash
docker stats nginx-workers
# OR
top -P  # (on macOS to see per-core distribution)
```

### 3. Run the Comparison
#### Phase A: Single Worker
1. Edit `nginx/nginx.conf`: `worker_processes 1;`
2. Restart NGINX.
3. Run benchmark:
   ```bash
   npx autocannon -c 100 -d 30 http://localhost:8080/
   ```

#### Phase B: Multiple Workers
1. Edit `nginx/nginx.conf`: `worker_processes auto;`
2. Restart NGINX.
3. Run benchmark:
   ```bash
   npx autocannon -c 100 -d 30 http://localhost:8080/
   ```

## 📊 Observations
See [insights.md](file:///Users/karan/projects/Personal_projects/understanding-nginx/phase-1/03-single-vs-multiple-workers/insights.md) for a detailed breakdown of the latency and throughput changes between the two configurations.
