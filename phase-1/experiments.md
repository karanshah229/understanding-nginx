# 🧪 Phase 1 — NGINX Deep Understanding via Experiments

> [!NOTE]
> **Goal:** Build intuition by observing real system behavior under controlled stress.

We will:
- [ ] Form a hypothesis
- [ ] Run an experiment
- [ ] Measure
- [ ] Validate or break the hypothesis

---

## ⚙️ Standard Setup (for ALL experiments)

> [!IMPORTANT]
> This setup applies to all experiments unless otherwise specified.

### 🛠️ Stack
- **NGINX**: Managed via Docker
- **Java Backend**: Spring Boot
- **Load Tools**: 
  - `autocannon`
  - `wrk`

### 📊 Metrics to ALWAYS observe
| Category | Metric | Collection Method / Tool |
| :--- | :--- | :--- |
| **System** | CPU Utilization | `top`, `htop` |
| **System** | Memory Usage | `free`, `htop` |
| **Resources** | Open File Descriptors (FDs) | `lsof | wc -l` |
| **Performance** | Latency (p50, p95, p99) | `autocannon`, `wrk` |
| **Performance** | Throughput (RPS) | `autocannon`, `wrk` |
| **Logs** | NGINX Access & Error Logs | `/var/log/nginx/` |

---

## 🧪 Experiment Group 1 — Baseline Understanding

### 🔬 Experiment 1: Static File Throughput
**Setup**: Serve a large file (100MB) via NGINX.

#### 💡 Hypothesis
NGINX achieves high throughput with low CPU due to **zero-copy (sendfile)**.

#### 📏 Measure
- CPU usage
- Throughput (MB/s)
- Latency

#### 🎓 Learn
- Kernel offloading
- Why NGINX is efficient for static content
- Difference between **CPU-bound** vs **kernel-assisted I/O**

---

### 🔬 Experiment 2: Reverse Proxy (Fast Backend)
**Setup**: NGINX → Spring Boot (fast response).

#### 💡 Hypothesis
NGINX adds minimal overhead in proxying.

#### 📏 Measure
- Latency delta (direct vs via NGINX)
- CPU usage

#### 🎓 Learn
- Proxy overhead baseline
- Cost of request forwarding

---

## 🧪 Experiment Group 2 — Concurrency & Event Loop

### 🔬 Experiment 3: Single Worker vs Multiple Workers
**Setup**: Run with:
1. One worker
2. N workers (N = CPU cores)

#### 💡 Hypothesis
Multiple workers reduce queueing delay and improve latency.

#### 📏 Measure
- p99 latency
- CPU utilization per core

#### 🎓 Learn
- Concurrency vs Parallelism
- Queueing delay visibility

---

### 🔬 Experiment 4: Connection Explosion
**Setup**: Scale from 10k → 100k concurrent connections.

#### 💡 Hypothesis
Few workers can handle massive concurrency due to non-blocking I/O.

#### 📏 Measure
- FD count
- Memory usage
- CPU

#### 🎓 Learn
- “Threads are **not required** for concurrency”
- Real cost of connections

---

## 🧪 Experiment Group 3 — Queueing & Latency

### 🔬 Experiment 5: Sudden Traffic Spike
**Setup**: Idle connections → sudden burst.

#### 💡 Hypothesis
Latency spikes due to event loop queueing, not necessarily CPU saturation.

#### 📏 Measure
- Latency distribution (p50 vs p99)
- CPU

#### 🎓 Learn
- Queueing delay is real
- Tail latency behavior

---

### 🔬 Experiment 6: Artificial Worker Imbalance
**Setup**: Skew traffic to a subset of connections.

#### 💡 Hypothesis
Some workers become overloaded while others stay idle.

#### 📏 Measure
- Latency variance
- CPU utilization per worker

#### 🎓 Learn
- Lack of dynamic load balancing
- Worker-level bottlenecks

---

## 🧪 Experiment Group 4 — Blocking & CPU Effects

### 🔬 Experiment 7: Inject Blocking Operation
**Setup**: Backend or NGINX (via Lua / config trick) introduces artificial delay.

#### 💡 Hypothesis
**Blocking stalls the entire worker.**

#### 📏 Measure
- Latency spike for **ALL** requests on that worker

#### 🎓 Learn
- Blast radius of blocking operations

---

### 🔬 Experiment 8: CPU-bound Backend
**Setup**: Spring Boot performs intensive CPU work.

#### 💡 Hypothesis
Throughput drops and latency increases despite low NGINX CPU.

#### 📏 Measure
- Backend CPU vs NGINX CPU
- Latency

#### 🎓 Learn
- Event loop ≠ CPU execution
- Separation of concerns

---

## 🧪 Experiment Group 5 — Backpressure

### 🔬 Experiment 9: Slow Backend (100ms delay)
**Setup**: Artificial delay in backend.

#### 💡 Hypothesis
Connections pile up → memory increases → latency increases.

#### 📏 Measure
- Active connections
- Memory usage
- Latency

#### 🎓 Learn
- Backpressure propagation
- Why slow upstream is dangerous

---

### 🔬 Experiment 10: Remove Limits
**Setup**: Disable rate limits and buffers.

#### 💡 Hypothesis
System becomes unstable and potentially crashes under heavy load.

#### 🎓 Learn
- Importance of backpressure controls

---

## 🧪 Experiment Group 6 — System Limits

### 🔬 Experiment 11: File Descriptor Limit
**Setup**: Set a low `ulimit -n`.

#### 💡 Hypothesis
NGINX fails before CPU is saturated.

#### 🎓 Learn
- OS limits > application limits

---

### 🔬 Experiment 12: Kernel Queue Limits
**Setup**: Reduce `somaxconn` at the kernel level.

#### 💡 Hypothesis
Connections are dropped during bursts despite NGINX capacity.

#### 🎓 Learn
- Kernel-level bottlenecks

---

## 🧪 Experiment Group 7 — Advanced Internals

### 🔬 Experiment 13: Keep-Alive Cost
**Setup**: Maintain many idle connections.

#### 💡 Hypothesis
Idle connections consume significant memory and FDs.

#### 🎓 Learn
- “Idle ≠ free”

---

### 🔬 Experiment 14: sendfile ON vs OFF
**Setup**: Toggle `sendfile` directive in NGINX.

#### 💡 Hypothesis
CPU usage increases significantly without zero-copy optimization.

#### 🎓 Learn
- Kernel optimization impact

---

### 🔬 Experiment 15: TLS Overhead
**Setup**: Enable HTTPS.

#### 💡 Hypothesis
CPU usage increases due to encryption/decryption overhead.

#### 🎓 Learn
- CPU vs I/O trade-offs
