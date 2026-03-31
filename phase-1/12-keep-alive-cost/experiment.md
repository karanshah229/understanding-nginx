# 🧪 Experiment 12 — Keep-Alive Cost

## 💡 The Hypothesis
Maintaining persistent "Keep-Alive" connections is **not free**. Each connection, even when completely idle, consumes a fixed amount of **Memory (RSS)** and a **File Descriptor (FD)**. We hypothesize that as the number of idle connections grows, memory usage will increase linearly, identifying the baseline cost of "holding" a connection.

## ⚙️ The Setup

- **NGINX**: Configured with `keepalive_timeout 3600` and `worker_connections 200000`.
- **Backend**: Spring Boot (Exp 11 parity) to handle initial requests.
- **Load Tool**: `autocannon` running in 4 parallel containers (12.5k connections each) to reach 50,000 total idle connections.
- **Metrics**: 
    - `docker stats` for Memory Usage.
    - `lsof` / `/proc/fd` for File Descriptor counts.
    - `stub_status` to verify "Waiting" (Keep-Alive) connections.

## 📏 What We are Measuring

### 1. Memory Growth (RSS)
- **Baseline**: 0 connections.
- **Steps**: 10k, 25k, 50k connections.
- **The Goal**: Calculate the cost per idle connection (Expected ~2.5 - 4 KB).

### 2. File Descriptor Consumption
- **The Goal**: Verify a 1:1 relationship between connections and FDs.
- **The Insight**: FDs are a finite OS resource; once exhausted, NGINX cannot accept new traffic even if CPU/RAM are available.

## 🏃 Running the Experiment

1.  **Start Services**:
    ```bash
    docker compose up --build -d
    ```
2.  **Monitor Connection Growth**:
    ```bash
    watch -n 1 "curl -s http://localhost:8080/nginx_status"
    ```
3.  **Capture Baseline and Scale Observations**:
    Run the consolidated benchmark script to record real-time metrics during the scale-up:
    ```bash
    ./scripts/benchmark.sh
    ```
4.  **Analyze Logs**:
    After the load-generator captures have stabilized, review the logs in the `measurements/` directory:
    - `nginx_status.log`: Correlation of active/waiting connections.
    - `docker_stats.log`: Memory usage## 📏 Measure

- Total **Waiting** connections in NGINX.
- **Memory (RSS)** usage of the NGINX container.
- Total **File Descriptors (FDs)** across all worker processes.

## 👀 Observe

- **Baseline Memory**: ~508 MiB (Idle NGINX + 6 Workers).
- **Peak Memory**: ~948.4 MiB @ 52,806 connections.
- **Memory Delta**: ~440.4 MiB.
- **FD Count**: ~54,423 sockets (1:1 mapping with connections).

## 🎓 Conclusion

The experiment **successfully validates** the linear memory growth for persistent connections. 
- **The Empirical Cost**: **~8.7 KB per idle connection.**
- **Strategic Insight**: While NGINX is highly efficient, capacity planning for high-concurrency systems (like real-time notification servers) must account for the **cumulative memory weight** of thousands of "Waiting" sockets, even when CPU usage is zero. 

### ⚙️ Bottleneck Summary
- **First Wall**: OS File Descriptor limits (`ulimit -n`).
- **Second Wall**: NGINX Worker processes (`worker_connections`).
- **Third Wall**: Available RAM for the cumulative connection state.
he end of this experiment, you will be able to calculate the exactly capacity of your NGINX cluster based on available RAM, moving from "guessing" to "architect-level capacity planning."
