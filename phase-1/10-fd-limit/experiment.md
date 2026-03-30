# 🧪 Experiment 10 — File Descriptor Limit

## 🎯 Objective

Understand OS limits.

## ⚙️ Setup

- NGINX restricted to `ulimit -n 128` in `compose.yml`.
- `worker_connections 1024` in `nginx.conf` (NGINX will attempt to exceed OS limits).
- Spring Boot backend on `/test`.
- Load generation via `autocannon` with 200 concurrent connections.

## 💡 Hypothesis

NGINX fails before CPU saturation because it hits the OS-level File Descriptor (FD) limit.

## 📏 Measure

- Errors (High error rate in `autocannon`).
- FD usage (Observe `lsof | wc -l` or NGINX error logs).
- CPU/Memory (Expect low utilization during failure).

## 👀 Observe

- **FD Limit hit at 61 connections**: NGINX refused to exceed 61 active proxy connections (122+ total FDs), despite 200 concurrent requests from `autocannon`.
- **"socket() failed (24: Too many open files)"**: Clear alerts in NGINX logs when attempting to connect to the upstream backend.
- **Low CPU (5 - 12%)**: NGINX was underutilized while thousands of requests failed or timed out.
- **Connection Resets & Timeouts**: `autocannon` reported 280 timeouts and hundreds of non-2xx responses.

## 📏 Measured Results

| Metric                 | Measured Value      | Log File / Source                     |
| ---------------------- | ------------------- | ------------------------------------- |
| **Total Requests**     | 27,000              | `measurements/autocannon_results.log` |
| **Max Concurrency**    | **61** (The "Wall") | `measurements/nginx_status.log`       |
| **Success Rate (2xx)** | ~95.3%              | `measurements/autocannon_results.log` |
| **Error Alert**        | **socket() failed** | `measurements/nginx_errors.log`       |
| **NGINX CPU Usage**    | **~5.13% Avg**      | `measurements/docker_stats.log`       |
| **FD Peak Count**      | **167**             | `measurements/nginx_fd_usage.log`     |

## 📊 Measurement Mapping (What we measured)

- **Throughput & Errors**: Tracked via `autocannon` results.
- **OS-Level Alerts**: Identified the specific kernel rejection in the NGINX error log.
- **Connection Saturation**: Observed the physical connection limit via `stub_status`.
- **System Footprint**: Measured CPU and Memory using `docker stats`.
- **Actual Resource Count**: Used `ls /proc/*/fd` to count total open file descriptors.

## 🎓 Learn

- **The FD Multiplier**: A reverse proxy needs **2 FDs per connection** (Client + Upstream). Your actual capacity is roughly half your system limit.
- **OS Limits > Application Limits**: `worker_connections 1024` is meaningless if `ulimit -n` is **128**.
- **Silent Failures**: High error rates can coexist with low CPU usage. Monitoring "saturation" (CPU) is not enough; you must monitor "starvation" (FDs).

---

## 🚀 Running the Experiment

1.  **Start the environment**:

    ```bash
    docker-compose up --build -d
    ```

2.  **Verify FD limits**:

    ```bash
    docker exec nginx ulimit -n
    # Should output 128
    ```

3.  **Run the benchmark**:

    ```bash
    bash scripts/benchmark.sh
    ```

4.  **Inspect logs for errors**:

    ```bash
    docker logs nginx | grep "Too many open files"
    ```

5.  **Stop the environment**:
    ```bash
    docker-compose down
    ```
