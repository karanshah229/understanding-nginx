# 🧪 Experiment 3 — Single Worker vs. Multiple Workers

## 💡 The Hypothesis
While NGINX’s event loop is highly efficient on a single core, total system throughput and **tail latency (p99)** are limited by a single worker's inability to utilize multi-core parallelism. Increasing `worker_processes` to match the CPU count should reduce queueing delays and improve latency distribution under heavy load.

## ⚙️ The Approach: "Concurrency vs. Parallelism"
To understand the impact of workers, we compare two distinct configurations:
- **Single Worker**: `worker_processes 1`. This tests the absolute efficiency of a single event loop.
- **Multiple Workers**: `worker_processes auto`. This tests NGINX's ability to distribute load across all available CPU cores.

### The Strategy:
We benchmark both configurations while proxying to a backend service, monitoring how the load is distributed across cores and how the latency profile shifts from a "skinny" p50 to a "fat" p99.

## 📏 What We Are Measuring

### 1. Latency Distribution (p50 / p95 / p99)
- **Expected Result**: Single worker will show higher p99 latency as it becomes a CPU bottleneck for event management. Multiple workers should provide a more consistent latency profile across all percentiles.

### 2. CPU Spread (Core Affinity)
- Observed via `htop` or `docker stats`.
- **The Proof**: Single worker will saturate a single core while others remain idle. Multiple workers should show even distribution across the host's CPU pool.

### 3. Throughput (RPS)
- **Goal**: Determine if additional workers enable higher aggregate throughput before the system hits the "Saturation" phase.

## 🎓 Target Learning
By the end of this experiment, you will understand:
- The difference between **Connection Concurrency** (handled by the event loop) and **Processing Parallelism** (handled by workers).
- Why `worker_processes auto` is the standard for production.
- How NGINX "shifts" queueing downstream rather than eliminating it.

---

## 🏁 Final Conclusion

**Workers scale the CPU; Event Loops scale the Connections.**

This experiment successfully demonstrated that NGINX’s performance is not just about its non-blocking I/O, but also about how that I/O is parallelized across hardware.

### 🧬 Key Findings:
1. **Parallel Efficiency**: Moving from 1 to N workers significantly reduced p99 latency spikes during concurrent bursts.
2. **Saturation Visibility**: NGINX does not mask downstream slowness. Instead, it surfaces it. During testing, the backend (Spring Boot) consistently saturated before NGINX, proving that the proxy's job is to efficiently handover work to the next layer.
3. **The Bottleneck**: A single worker can handle thousands of concurrent *connections*, but it can only handle one *event* at a time. Multi-worker architecture is the key to decoupling connection state from request processing.

To build a high-performance system, always align your **Worker Count** with your **Physical CPU Cores** to maximize parallel event management.
