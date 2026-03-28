# 🧪 Experiment 1 — Operating Guide

> [!NOTE]
> For the core hypothesis and architectural goals, see [experiment.md](file:///Users/karan/projects/Personal_projects/understanding-nginx/phase-1/01-static-files/experiment.md).

## 🏛️ Architecture
- **Proxy**: NGINX (serving a 100MB static binary).
- **Optimization**: `sendfile on;` vs `sendfile off;`.
- **Load Tool**: `wrk`.

## ⚙️ Setup

### Prerequisites
- Docker.
- `dd` utility for file generation.

### Directory Structure
```text
.
├── experiment.md
├── README.md
├── nginx.conf
└── Dockerfile
```

## 🚀 Execution Guide

### 1. Generate the Large Static Asset (100MB)
Run this command in the current directory:
```bash
dd if=/dev/zero of=large.bin bs=1m count=100
```

### 2. Build and Start the Container
```bash
docker build -t nginx-static .
docker run -p 8080:8080 nginx-static
```

### 3. Monitor CPU Usage (Target Terminal)
Open a dedicated terminal and run:
```bash
docker stats
```

### 4. Run the Head-to-Head Comparison
#### Phase A: sendfile ON
1. Ensure `nginx.conf` has `sendfile on;`.
2. Restart the container.
3. Run benchmark:
   ```bash
   wrk -t4 -c20 -d20s http://localhost:8080/large.bin
   ```

#### Phase B: sendfile OFF
1. Ensure `nginx.conf` has `sendfile off;`.
2. Restart the container.
3. Run benchmark:
   ```bash
   wrk -t4 -c20 -d20s http://localhost:8080/large.bin
   ```

## 📊 Observations
See [experiment.md](file:///Users/karan/projects/Personal_projects/understanding-nginx/phase-1/01-static-files/experiment.md) for the performance breakdown (8% vs 40% CPU usage) and the architectural analysis of Zero-Copy efficiency.
