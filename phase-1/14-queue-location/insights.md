# 🎓 Experiment 14 — Insights: Where Does the Queue Live?

> **The Architect's Dilemma**: You cannot avoid a queue when load exceeds capacity. You can only choose where it lives and how it fails.

---

### 📊 Empirical Comparison (Actual Results)

| Metric | **Scenario A: Kernel** | **Scenario B: NGINX** | **Scenario C: Backend** |
| :--- | :--- | :--- | :--- |
| **Success Rate** | Very Low (Drops) | Controlled (10 RPS) | 100% (Congested) |
| **Max Latency** | **9237ms** (Red Alert 🚨) | 3247ms | 2021ms |
| **Avg Latency** | 17ms (Bimodal) | **12ms** (Fast) | 992ms (Wait time) |
| **Telemetry Signal**| `TcpExtListenOverflows` | `Stub Status: Waiting` | `Active Threads: 50` |

---

### 🧠 Deep-Dive Insights

#### 1. The "9-Second Mystery" (TCP Retransmissions)
In Scenario A (Kernel Queue), the average latency was low, but the **Max Latency hit 9 seconds**. 
*   **Why?** When the Kernel backlog is full, it silent-drops the SYN packet. The client's TCP stack waits for a **Retransmission Timeout (RTO)**. 
*   **Architect Note:** These retransmissions (1s, 3s, 7s...) are the primary cause of "random" long-tail latency in over-saturated systems. If you don't monitor `nstat`, these spikes are impossible to debug.

#### 2. Admission Control & The "Speed of Success"
In Scenario B (NGINX Queue), we limited the rate to 10r/s. 
*   **Observation:** Even under massive load (100 concurrency), the users who "got in" experienced an average latency of **12ms**.
*   **Principle:** **Load Shedding preserves quality of service.** It is better to give 10 users a perfect experience than to give 100 users a broken one.

#### 3. Proxy Pollution (Scenario C)
When the queue lived in the Backend (Scenario C), NGINX reported a high number of **"Writing"** connections (~100).
*   **Observation:** NGINX was forced to hold 100 sockets open for ~1s each. 
*   **Risk:** This "Backpressure" consumes File Descriptors and Memory on the proxy. A slow backend can literally "choke" the proxy, making it unable to serve other (healthy) backends.

---

### 🏗️ Final Mental Model for Architects

When designing for high scale, ask: **"Where do I want my users to wait?"**

-   **Wait in the Kernel?** ❌ Dangerous. Invisible drops and high retransmission penalties.
-   **Wait in the Backend?** ❌ Risky. Slows down the entire system and pollutes the proxy.
-   **Wait in NGINX?** ✅ Recommended. Controlled wait-times, early errors for excess load (503), and protection for the upstream.

👉 **Architectural Stability requires the queue to be explicitly managed at the NGINX layer.**
