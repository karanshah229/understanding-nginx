# 🧠 Key Insights: Experiment 6 — Slow Backend (Backpressure Propagation)

## 🏗️ Architectural Thinking: The "Clog" Moving Upstream

This experiment proved that a system's capacity is not defined by its fastest component, but by its slowest sink. We observed how slowness at the **Backend** physically forced the **Proxy** to consume more resources.

---

### 📊 Observation Results (Finalized)
| Phase | Throughput (RPS) | Avg Latency | Active Connections (NGINX) | NGINX Memory (MB) |
| --- | --- | --- | --- | --- |
| **Baseline (10 conc)** | ~92 | 108ms | ~12 | 6.5 MB |
| **Saturation (200 conc)** | ~482 | 409ms | 202 | 9.8 MB |
| **Breaking Point (1500 conc)** | ~486 | 2776ms | 1502 | **32.7 MB** |

---

### 💡 Insight 1: Connection Accumulation (State is Not Free)
NGINX memory usage increased by **5x** (from 6.5MB to 32.7MB) while throughput stayed exactly the same (~480 RPS).
- **The Lesson**: When the backend is slow, NGINX is forced to "hold the line." Each connection is a file descriptor and a memory buffer. 
- **The Architect's Rule**: High latency downstream creates a mandatory **resource tax** upstream. You must budget NGINX memory based on your *worst-case* backend latency, not your average.

### 💡 Insight 2: Queueing vs. Processing (The 1:30 Ratio)
In the Breaking Point phase, the user waited **2,776ms**, but the server only did **100ms** of real work. 
- **The Lesson**: **96% of the user's time** was spent waiting in a queue managed by NGINX. 
- **The Architect's Rule**: In a saturated system, **Latency is a function of Concurrency, not Speed.** To fix this, you don't make the backend "faster"; you decrease the concurrency (via rate limiting) or increase the service rate (via horizontal scaling).

### 💡 Insight 3: Backpressure Propagation
We observed NGINX easily handling 1,500 connections despite a 1,024 limit because of its **multi-worker event loop**. 
- **The Warning**: NGINX is so efficient at holding queues that it can **hide** a backend failure until the system hits a hard limit (like OS File Descriptors).
- **The Architect's Rule**: If your proxy's "Active Connections" is climbing while "RPS" is flat, your backend is already dead. You are just watching the "clog" fill the pipe.

---

### 🎓 Final Conclusion
**"Slowness is more dangerous than failure."**

A dead backend is easy to handle (502 error, immediate). A slow backend propagates backpressure, consumes proxy memory, and turns a small service delay into a systemic connection exhaustion. 

**Architectural Prevention**:
1. **Set `proxy_connect_timeout` and `proxy_read_timeout`** aggressively.
2. **Use `limit_conn`** in NGINX to prevent a single slow service from eating all worker connections.
3. **Always monitor "Active Connections"**—it is the leading indicator of backpressure.
