# 🧪 Experiment 6 — Slow Backend (Backpressure Propagation)

## 🎯 Objective
Understand how slowness propagates upstream and affects the overall system state. This experiment demonstrates the "Physics of Backpressure" — showing that a downstream delay isn't just a latency issue; it's a resource consumption issue for everyone in the chain.

## ⚙️ Setup
- **Backend (Spring Boot)**: Artificially delayed by **100ms** per request.
- **NGINX (Reverse Proxy)**: Configured with `proxy_buffering off` to ensure immediate propagation.
- **Monitoring**: Using NGINX's `stub_status` module to observe active connections.

## 💡 Hypothesis
A slow backend causes:
1.  **Connection Buildup**: NGINX will hold open a massive number of active connections because it's waiting for the backend to respond.
2.  **Increased Latency**: As the backend saturates, latency will spike for *all* users.
3.  **Memory Growth**: Each open connection consumes NGINX memory.

## 📏 Measure
- **Active Connections** (`stub_status`): How many concurrent sockets are open?
- **NGINX Memory Usage** (`docker stats`): Does memory footprint increase as connections pile up?
- **p99 Latency** (`autocannon`): How much does the last 1% of users suffer?

## 👀 Observe (Final Results)
- **Step 1 (Baseline)**: 108ms Avg Latency | 12 Active Connections.
- **Step 2 (Saturation)**: 409ms Avg Latency | **202 Active Connections**.
- **Step 3 (Breaking Point)**: 2776ms Avg Latency | **1502 Active Connections**.
- **Memory Impact**: NGINX memory grew from **6.5MB to 32.7MB** under load.

## 🎓 Learn
- **Backpressure flows backward**: The slowest component (the sink) determines the resource cost of the entire upstream system.
- **NGINX is a State Holder**: Even if NGINX isn't "doing work" (CPU remained <10%), it is "holding state" (Memory/FDs are high).
- **Infinite Queues are Latency Bombs**: Without a load-shedding mechanism (like rate limiting), a slow backend can take down the entire edge layer via resource exhaustion.
