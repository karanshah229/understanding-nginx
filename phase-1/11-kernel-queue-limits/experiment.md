# 🧪 Experiment 11 — Kernel Queue Limits

## 🎯 Objective

Understand kernel-level TCP bottlenecks.

## ⚙️ Setup

- **NGINX Restricted Backlog**: `listen 8080 backlog=5;` in `nginx.conf`.
- **Kernel Listen Limit**: `sysctls: net.core.somaxconn=5` in `compose.yml`.
- **Backend**: Spring Boot on `/` (from Experiment 10).
- **Load Generation**: `autocannon` with 100 concurrent connections.

## 💡 Hypothesis

When a burst of connections exceeds the kernel's listen queue size, the kernel will drop the initial SYN packets. This results in:
1.  **Connection Errors**: The client (autocannon) will report failed connections.
2.  **Latency Spikes**: Connections that are dropped and then retried (TCP exponential backoff) will show extremely high tail latency (P99+).
3.  **Low App Stress**: NGINX and the Backend will appear healthy/idle, as the "dropped" connections never even reach the application layer.

## 📏 Measure

- **Connection Errors** (High in `autocannon`).
- **Tail Latency** (P99/Max latency in `autocannon`).
- **System Stats** (Expect low CPU/Memory as connections are rejected early).

## 👀 Observe

- **Initial Burst Drops**: The kernel logic immediately rejected 16+ connections in the first second of the test, as shown in `kernel_drops.log`.
- **Latency Outliers**: Some connections experienced up to **~5 seconds** of latency due to TCP retransmission backoff, despite the average being much lower.
- **Application Silence**: NGINX logs showed `200 OK` for all accepted traffic and zero errors, hiding the fact that connections were being dropped at the OS layer.
- **Resource Headroom**: CPU usage remained extremely low (< 10%), proving that the bottleneck was structural (queue size) rather than resource-based (compute power).

## 📏 Measured Results

| Metric                  | Measured Value       | Log File / Source                     |
| ----------------------- | -------------------- | ------------------------------------- |
| **Total Requests**      | ~17,000              | `measurements/autocannon_results.log` |
| **Max Latency**         | **~4,904 ms**        | `measurements/autocannon_results.log` |
| **P99 Latency**         | **~893 ms**          | `measurements/autocannon_results.log` |
| **Kernel SYNs Dropped** | **16** (Total)       | `measurements/kernel_drops.log`       |
| **NGINX CPU Usage**     | **< 10%**            | `measurements/docker_stats.log`       |
| **NGINX Error Count**   | **0** (False Sense)  | `measurements/nginx_errors.log`       |

---

## 🚀 Running the Experiment

1.  **Start the environment**:
    ```bash
    docker-compose up --build -d
    ```

2.  **Verify kernel limit**:
    ```bash
    docker exec nginx sysctl net.core.somaxconn
    # Should output 5
    ```

3.  **Run the benchmark**:
    ```bash
    bash scripts/benchmark.sh
    ```

4.  **Inspect logs**:
    Check `measurements/autocannon_results.log` for connection errors.

5.  **Stop the environment**:
    ```bash
    docker-compose down
    ```
