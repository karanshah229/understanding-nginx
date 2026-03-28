# 🧪 Phase 1 — NGINX Experiments (1-Pagers)

> Goal: Build deep intuition by observing real system behavior under controlled stress.

---

# ⚙️ Standard Setup (Applies to ALL Experiments)

## 🛠️ Stack

- NGINX (Docker)
- Backend: Spring Boot (Java)
- Load tools:
    - autocannon
    - wrk

## 📊 Metrics to Observe

| Category    | Metric                  | Tool                |
| ----------- | ----------------------- | ------------------- |
| CPU         | Utilization per core    | top / htop          |
| Memory      | Usage                   | htop / docker stats |
| FDs         | Open file descriptors   | lsof \| wc -l       |
| Performance | Latency (p50, p95, p99) | autocannon / wrk    |
| Performance | Throughput (RPS)        | autocannon / wrk    |
| Logs        | Access / errors         | nginx logs          |

---

# 🧪 Experiment 1 — Static File Throughput

## 🎯 Objective

Understand why NGINX is extremely efficient for static content.

## ⚙️ Setup

- Serve a large file (100MB) via NGINX
- Toggle:
    - `sendfile on`
    - `sendfile off`

## 💡 Hypothesis

NGINX achieves high throughput with low CPU using **zero-copy (sendfile)**.

## 📏 Measure

- CPU usage
- Throughput (MB/s)
- Latency

## 👀 Observe

- CPU drop with sendfile ON
- Memory differences
- Similar throughput despite CPU differences

## 🎓 Learn

- Kernel offloading (zero-copy)
- CPU vs kernel-assisted I/O
- Why NGINX excels at static serving

---

# 🧪 Experiment 2 — Reverse Proxy (Fast Backend)

## 🎯 Objective

Understand proxy overhead and system-level effects.

## ⚙️ Setup

- Direct: Client → Backend
- Proxy: Client → NGINX → Backend

## 💡 Hypothesis

NGINX adds minimal overhead but introduces **admission control**.

## 📏 Measure

- Latency
- RPS
- CPU (NGINX vs Backend)

## 👀 Observe

- Latency often improves via NGINX
- RPS drops
- Backend CPU stabilizes

## 🎓 Learn

- NGINX acts as **backpressure layer**
- Throughput vs latency tradeoff
- System stability > raw throughput

---

# 🧪 Experiment 3 — Single Worker vs Multiple Workers

## 🎯 Objective

Understand concurrency vs parallelism.

## ⚙️ Setup

Run NGINX with:

- 1 worker
- N workers (N = CPU cores)

## 💡 Hypothesis

Multiple workers reduce queueing delay and improve latency.

## 📏 Measure

- p50 / p99 latency
- CPU utilization per core

## 👀 Observe

- Single worker → high p99 latency
- Multiple workers → better latency distribution
- CPU spreads across cores

## 🎓 Learn

- Event loop = concurrency
- Workers = parallelism
- Queueing delay is real

---

# 🧪 Experiment 4 — Connection Explosion

## 🎯 Objective

Test scalability of non-blocking architecture.

## ⚙️ Setup

- Gradually increase connections:
    - 10k → 50k → 100k

## 💡 Hypothesis

Few workers can handle massive concurrency.

## 📏 Measure

- FD count
- Memory usage
- CPU

## 👀 Observe

- CPU remains low
- Memory grows linearly
- FD usage increases

## 🎓 Learn

- Threads are NOT required for concurrency
- Idle connections still cost memory + FDs
- Scalability is I/O-bound, not CPU-bound

---

# 🧪 Experiment 5 — Sudden Traffic Spike (Queue Formation)

## 🎯 Objective

Understand queueing behavior.

## ⚙️ Setup

- Maintain idle connections
- Suddenly send requests from all clients

## 💡 Hypothesis

Latency spikes due to queue buildup, not CPU saturation.

## 📏 Measure

- p50 vs p99 latency
- CPU usage

## 👀 Observe

- CPU may remain low
- p99 latency spikes massively

## 🎓 Learn

- Queueing delay dominates latency
- Tail latency is critical
- “Low CPU” ≠ “healthy system”

---

# 🧪 Experiment 6 — Slow Backend (Backpressure Propagation)

## 🎯 Objective

Understand how slowness propagates upstream.

## ⚙️ Setup

- Add artificial delay (e.g., 100ms) in backend

## 💡 Hypothesis

Slow backend causes:

- Connection buildup
- Increased latency
- Memory growth

## 📏 Measure

- Active connections
- Memory usage
- Latency

## 👀 Observe

- Requests pile up
- Latency increases across system

## 🎓 Learn

- Backpressure flows backward
- Upstream dictates system performance

---

# 🧪 Experiment 7 — Remove Backpressure Controls

## 🎯 Objective

Understand failure behavior.

## ⚙️ Setup

- Disable limits (connections, buffers, rate limiting)

## 💡 Hypothesis

System becomes unstable under load.

## 📏 Measure

- Errors
- Memory
- Latency

## 👀 Observe

- Memory spikes
- Errors increase
- Possible crashes

## 🎓 Learn

- Load shedding is critical
- Stability requires limits

---

# 🧪 Experiment 8 — CPU-bound Backend

## 🎯 Objective

Understand CPU bottlenecks.

## ⚙️ Setup

- Backend performs CPU-heavy work

## 💡 Hypothesis

Latency increases despite low NGINX CPU.

## 📏 Measure

- Backend CPU vs NGINX CPU
- Latency

## 👀 Observe

- Backend CPU saturates
- NGINX remains idle
- Latency increases

## 🎓 Learn

- Event loop ≠ compute engine
- Separation of concerns

---

# 🧪 Experiment 9 — Worker Imbalance

## 🎯 Objective

Understand lack of dynamic load balancing.

## ⚙️ Setup

- Use uneven connection patterns
- Long-lived connections on some workers

## 💡 Hypothesis

Some workers overload while others remain idle.

## 📏 Measure

- CPU per worker
- Latency distribution

## 👀 Observe

- Uneven CPU usage
- Latency spikes on overloaded worker

## 🎓 Learn

- Workers don’t rebalance existing connections
- Load distribution is not perfect

---

# 🧪 Experiment 10 — File Descriptor Limit

## 🎯 Objective

Understand OS limits.

## ⚙️ Setup

- Reduce `ulimit -n`

## 💡 Hypothesis

NGINX fails before CPU saturation.

## 📏 Measure

- Errors
- FD usage

## 👀 Observe

- Connection failures
- System underutilized CPU

## 🎓 Learn

- OS limits > application limits
- FD exhaustion is a real bottleneck

---

# 🧪 Experiment 11 — Kernel Queue Limits

## 🎯 Objective

Understand kernel bottlenecks.

## ⚙️ Setup

- Reduce `somaxconn`

## 💡 Hypothesis

Connections drop under burst load.

## 📏 Measure

- Connection errors
- Latency

## 👀 Observe

- Drops during spikes

## 🎓 Learn

- Kernel is part of the system
- Not all limits are visible in app layer

---

# 🧪 Experiment 12 — Keep-Alive Cost

## 🎯 Objective

Understand cost of idle connections.

## ⚙️ Setup

- Maintain large number of idle keep-alive connections

## 💡 Hypothesis

Idle connections consume resources.

## 📏 Measure

- Memory
- FD usage

## 👀 Observe

- Memory increases with connections

## 🎓 Learn

- Idle ≠ free
- Resource planning is critical

---

# 🧪 Experiment 13 — TLS Overhead

## 🎯 Objective

Measure encryption cost.

## ⚙️ Setup

- Enable HTTPS

## 💡 Hypothesis

CPU usage increases due to TLS.

## 📏 Measure

- CPU usage
- Latency

## 👀 Observe

- Increased CPU
- Slight latency increase

## 🎓 Learn

- CPU vs I/O tradeoff
- TLS termination cost

---

# 🧪 Experiment 14 — Where Does the Queue Live?

## 🎯 Objective

Understand where queueing happens.

## ⚙️ Setup

Introduce slowdown at:

1. Kernel (backlog)
2. NGINX (limits)
3. Backend (delay)

## 💡 Hypothesis

Queue location changes system behavior.

## 📏 Measure

- Latency
- Errors
- CPU

## 👀 Observe

- Different failure patterns

## 🎓 Learn

- Queue placement defines architecture
- Same load, different outcomes

---

# 🧠 Final Mental Model

> Performance issues are rarely about "speed" —  
> they are about **where work waits**.

- CPU-bound → compute problem
- Queueing → latency problem
- Limits → system problem

👉 Always ask:

**“Where is the bottleneck, and where is the queue?”**
