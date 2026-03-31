# 🧪 Experiment 14 — Where Does the Queue Live?

## 🎯 Objective
Empirically prove that **system behavior is defined by where the queue resides**, not just the average "speed" of the backend. We will isolate the bottleneck at three distinct layers: the **Kernel**, **NGINX**, and the **Application**.

---

## 🏗️ The 3-Port Isolation Model
We use a single NGINX instance listening on three different ports to simulate three architectural bottlenecks:

| Port | Bottleneck Location | Configuration Trick |
| :--- | :--- | :--- |
| **8001** | **OS Kernel** | `listen 8001 backlog=1` + `sysctl somaxconn=5` |
| **8002** | **NGINX Proxy** | `limit_req_zone` (Admission Control) |
| **8003** | **Backend App** | High concurrency (100) vs. Small thread pool (50) |

---

## 💡 Hypothesis: Signature of Failure
Each layer has a unique "failure signature" that defines how the system degrades:

1.  **The Kernel Queue (L4 Layer)**: Connections are dropped before the app even sees them. **Result:** High connection errors, but zero latency impact on successful requests.
2.  **The NGINX Queue (L7 Proxy)**: Handled via specialized "Waiting Rooms" (limit zones). **Result:** Managed errors (503s) and predictable, fast service for admitted users.
3.  **The Backend Queue (L7 App)**: Saturation of the language runtime (Tomcat/JVM). **Result:** System-wide slowdown as every request waits for a thread.

---

## 📏 Measurement Checklist
- [ ] **Kernel Telemetry**: `nstat -az TcpExtListenOverflows` (The only way to see Scenario A).
- [ ] **Proxy Telemetry**: `stub_status` mapping "Waiting" vs "Writing" connections.
- [ ] **App Telemetry**: Internal `/management/threads` filter to see active JVM request counts.

---

## 🚀 Running the Experiment

1.  **Start the environment**:
    ```bash
    docker-compose up --build -d
    ```

2.  **Run the automated benchmark**:
    ```bash
    bash scripts/benchmark.sh
    ```

3.  **Analyze the "Why"**:
    Compare `measurements/kernel_drops.log` and `measurements/nginx_status.log` to see the internal signals that the client never sees.
