# 🧪 Experiment 8 — CPU-bound Backend

## 🎯 Objective
Understand CPU bottlenecks: how a compute-heavy backend affects the overall system stack.

## ⚙️ Setup
- **NGINX**: Standard reverse proxy.
- **Backend**: Spring Boot performing recursive `Fibonacci(30)` on each request.
- **CPU Cap**: Backend limited to 0.5 cores via Docker Compose.

## 💡 Hypothesis
Latency will increase exponentially as the backend CPU saturates, despite NGINX itself remaining at extremely low CPU utilization.

## 📏 Measure
- **Backend CPU vs NGINX CPU** (`docker stats`)
- **Latency (Avg, p99)** (`autocannon`)
- **Throughput (RPS)** (`autocannon`)

## 👀 Observe (Comparative Metrics)
| Metric | C=20 (Previous Run) | C=30 (Latest Run) | % Change |
| :--- | :--- | :--- | :--- |
| **Backend CPU** | 49.16% | 49.16% | **0%** (Saturated) |
| **NGINX CPU** | 1.59% | 1.62% | **Negligible** |
| **Throughput** | 76.5 RPS | 78.1 RPS | **+2%** (Noise) |
| **Avg Latency** | 260.2 ms | 382.6 ms | **+47%** |
| **p99 Latency** | 602 ms | 996 ms | **+65%** |

**Conclusion**: We have hit the **Throughput Ceiling**. Increasing concurrency by 50% (20 -> 30) provided almost zero throughput gain but penalized average latency by nearly 50%.

## 🎓 Learn
- **Event loop ≠ compute engine**: NGINX is an I/O manager, not a computational worker.
- **Queueing Theory**: Once the service rate (0.5 CPU) is exceeded, increasing arrival rate (concurrency) only extends the queue length and latency.
- **Scaling Strategy**: This bottleneck can only be solved by adding more CPU (Vertical) or more backend instances (Horizontal).
