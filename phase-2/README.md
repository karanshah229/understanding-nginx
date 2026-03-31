# 🚀 Phase 2: Orchestration (Production Hardening)

Welcome to the "Orchestration" phase. In Phase 2, we move from observing internal mechanics to **Defensive Edge Architecture.** 

This phase is about transforming NGINX from a single binary into a distributed, resilient, and highly observable gateway that can survive the chaos of real-world internet traffic.

---

## 🏛️ The Philosophy: "Zero-Downtime Resilience"
A standalone NGINX node is a Single Point of Failure (SPOF). A high-performance proxy without backpressure is a "latency bomb." 

Success in this phase means you can design a system that survives even when backends "limp," caches "expire," and clients "misbehave."

---

## 🔬 Project 2.1: High Availability (Multi-NGINX Clusters)
**Objective**: Eliminate the Single Point of Failure at the edge using floating IPs.

### 🎓 Core Concepts:
- **VRRP (Virtual Router Redundancy Protocol)**: The standard networking protocol used for VIP (Virtual IP) failover.
- **Keepalived**: The daemon that manages the VRRP state and local health checks.
- **Priority & Preemption**: Controlling which node is the "Master" and how it reclaims its role after a restart.

### 🛠️ The Experiment Suite:
1.  **Failover Timing**: Measuring the "Drop Delta" during a hard crash (`kill -9`).
2.  **Health-Check Failover**: Triggering a failover by failing an arbitrary health script (e.g., checking for existence of a file).
3.  **Split-Brain Avoidance**: Understanding why priority gaps and authentication are critical.

---

## 🔬 Project 2.2: Edge Caching & CDNs (The Tiered Infrastructure)
**Objective**: Protect the origin backend and optimize p50 latency via hierarchical caching.

### 🎓 Core Concepts:
- **`proxy_cache_path`**: 
    - `levels=1:2`: Managing the directory hierarchy to avoid "Too many files" errors.
    - `keys_zone=my_cache:10m`: Defining shared memory for the metadata index.
    - `inactive=60m`: When to purge an element from the index.
- **`stale-while-revalidate`**: Serving old content while NGINX updates the background cache.
- **`proxy_cache_use_stale`**: The primary directive for backend survivability.

### 🛠️ The Experiment Suite:
1.  **Hierarchical Purging**: Implementing selective cache invalidation.
2.  **Stale Survival**: Killing the backend and proving the site remains 100% functional via the cache.

---

## 🔬 Project 2.3: Traffic Shaping & Admission Control
**Objective**: Protect against abuse and thundering herds through "Selective Shedding."

### 🎓 Core Concepts:
- **Leaky Bucket Algorithm (`limit_req`)**: Smoothing out traffic spikes into a steady stream.
- **Admission Control**: Returning `503 Service Unavailable` to low-priority traffic to reserve capacity for authenticated users.

### 🛠️ The Experiment Suite:
1.  **Burst vs. Delay**: Understanding the difference between smoothing traffic (`nodelay`) and queuing traffic.
2.  **The "Script Kiddie" Defense**: Identifying and shedding high-frequency malicious IPs.

---

## 🔬 Project 2.4: Observability & The Golden Signals
**Objective**: Build a real-time visualization of system health.

### 🎓 Core Concepts:
- **`stub_status`**: The built-in metrics module.
    - `Active`: Handshakes + Requests.
    - `Waiting`: Idle Keepalive connections.
- **Structured JSON Logging**: Configuring `log_format` for automated metric extraction.
- **Prometheus Integration**: Exporting metrics for long-term trend analysis.

### 🛠️ The Experiment Suite:
1.  **Golden Signal Visualization**: Building a Grafana dashboard for Latency, Traffic, Errors, and Saturation.
2.  **The Latency Delta**: Correlating `$request_time` vs. `$upstream_response_time`.

---

## 🔬 Project 2.5: The Hardening Lab (8 Advanced Scenarios)
**Objective**: Intentionally break the system and apply "Principal Architect" level fixes.

### 🏥 The Hardening Ladder (Difficulty Level 1–8):

### 🔬 Level-by-Level Hardening Deep Dive:

#### **Level 1: The "Header Wall" (Memory Limits)**
*   **Objective**: Witness how oversized client headers (cookies, JWTs) can trigger a silent `400 Bad Request`.
*   **Technical Deep Dive**: NGINX allocates a fixed set of buffers for reading headers. If the total buffer size is smaller than the incoming header, the request is rejected. This is usually the culprit for enterprise Auth failures.
*   **The Directive Suite**: `large_client_header_buffers 4 16k;` — Allocates up to 4 buffers of 16KB each for large headers.
*   **Simulation Strategy**: Use `curl -H "Cookie: [10KB_STRING]"` to exceed the default buffer size (usually 8KB) and trigger the failure.

#### **Level 2: The "Log Bottleneck" (I/O Blocking)**
*   **Objective**: Decouple request processing from disk performance.
*   **Technical Deep Dive**: Every `access_log` write is traditionally synchronous. Under high RPS (10k+), the NGINX worker must "wait" for the disk-write confirmation before it can process the next event. If the disk is slow, the whole site lags.
*   **The Directive Suite**: `access_log ... buffer=32k flush=1m;` — Batches writes into 32KB chunks and flushes every minute (or when full).
*   **Simulation Strategy**: Use `stress-ng --hdd 1` to saturate disk I/O while running a high-RPS benchmark and measure p99 latency with vs. without buffering.

#### **Level 3: The "Zombie Worker" (Process Lifecycle)**
*   **Objective**: Prevent "Configuration Bloat" during high-frequency reloads.
*   **Technical Deep Dive**: When a reload occurs, the Old Worker process stays alive until all its active connections are closed. A single 1-hour websocket or a slow client can keep an "Old Worker" alive indefinitely, consuming RAM.
*   **The Directive Suite**: `worker_shutdown_timeout 30s;` — Forces the old worker to exit after 30 seconds, even if it has active connections.
*   **Simulation Strategy**: Start a long-running `curl --limit-rate 10k` download, trigger `nginx -s reload`, and observe the `ps aux` process list before and after the timeout.

#### **Level 4: The "Stale DNS" (Dynamic Resolution)**
*   **Objective**: Enable NGINX to follow dynamic backend IP changes (AWS/K8s).
*   **Technical Deep Dive**: Standard `proxy_pass http://backend;` resolves the IP **only at startup**. If the backend IP changes, NGINX is stuck. To force runtime resolution, you must use a variable in the `proxy_pass` directive.
*   **The Directive Suite**: `resolver 127.0.0.11; set $backend "http://app:8080"; proxy_pass $backend;` — Forces NGINX to consult the DNS resolver at runtime.
*   **Simulation Strategy**: Docker-scale the backend to replace instances with new IPs, then watch NGINX fail until the resolver pattern is applied.

#### **Level 5: The "Upstream Connection Storm" (Handshake Churn)**
*   **Objective**: Reduce backend CPU load by stabilizing the connection pool.
*   **Technical Deep Dive**: Without keepalive, NGINX closes the backend connection after every single request. At 5k RPS, you are doing 5,000 TCP/TLS handshakes per second, which kills backend performance via CPU-churn.
*   **The Directive Suite**: `upstream { keepalive 32; }` + `proxy_http_version 1.1;` — Maintains a pool of open, idle connections to the backend.
*   **Simulation Strategy**: Compare "Requests per Second" (RPS) and CPU usage on the backend node during a sustained benchmark with and without keepalive enabled.

#### **Level 6: The "Slow Client" (Backpressure Shielding)**
*   **Objective**: Prevent "The Limping Edge" from exhausting backend threads.
*   **Technical Deep Dive**: If a mobile client is on a 2G connection, it reads data very slowly. Without buffering, the backend thread must stay open for the entire duration of the client read. NGINX buffering allows the backend to dump the response "instantly" and move on.
*   **The Directive Suite**: `proxy_buffering on; proxy_buffers 16 32k;` — Uses memory/disk to buffer the backend response at the edge.
*   **Simulation Strategy**: Use `toxiproxy` to simulate a 10kbps client throttle while monitoring backend thread utilization.

#### **Level 7: The "Limping Node" (Gray Failure Recovery)**
*   **Objective**: Fail-over before a health check even triggers.
*   **Technical Deep Dive**: Active health checks are periodic. Passive checks (`max_fails`) happen in-line. If a node returns 3 errors, NGINX skips it for 30s. `slow_start` prevents a newly recovered node from "Cold Cache" saturation.
*   **The Directive Suite**: `server app:8080 max_fails=3 fail_timeout=30s slow_start=30s;`
*   **Simulation Strategy**: Induce a "Flaky Backend" that returns `500` for 20% of requests and observe NGINX automatically routing around it.

#### **Level 8: The "Thundering Herd" (Concurrency Mutex)**
*   **Objective**: Protect backends from cache-expiration "dog-piling."
*   **Technical Deep Dive**: A hot cache key expires. 1,000 concurrent requests all miss the cache simultaneously. All 1,000 hit the backend to "repopulate" the cache. The backend collapses under the storm.
*   **The Directive Suite**: `proxy_cache_lock on; proxy_cache_use_stale updating;` — Ensures only **one** request hits the backend; others wait for the first to return and fill the cache.
*   **Simulation Strategy**: Run a high-load benchmark against a single cache key, manually expire it, and watch the backend connection count using `stub_status`.

---

## 🏁 The Phase 2 Evaluation
By completing the Hardening Lab, you have crossed the threshold from "Operator" to "Architect." You possess the defensive playbooks used by global-scale engineering teams.

**Next Step**: Move to [**Phase 3: Evaluation**](../phase-3/README.md) to compare NGINX against HAProxy and Envoy.
