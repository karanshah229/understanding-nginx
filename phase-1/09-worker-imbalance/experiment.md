# 🧪 Experiment 9 — Worker Imbalance (Gzip Stress)

## 🎯 Objective
Understand how CPU-intensive tasks inside NGINX workers can cause load imbalance and process-level Head-of-Line blocking.

## ⚙️ Setup
- **NGINX Configuration**: `worker_processes 2` with `gzip on` and `gzip_comp_level 9` only on the `/slow` endpoint.
- **Data Transfer**: Backend returns a 10MB repetitive string for the `/slow` endpoint to force maximum compression## 3. Bi-Modal Latency Distribution
In our Stress Test, we observed an extreme "two-humped" distribution:
- **Fast Path (p50: 3ms)**: Requests that landed on the idle worker.
- **Slow Path (p99: 102ms, Max: 593ms)**: Requests that were "trapped" on the busy worker.
The overall **p99 latency** is dictated by the busiest worker. When that worker is busy with synchronous CPU tasks, the event loop effectively "pauses" for all other connections on that same process.

## 💡 Hypothesis
NGINX's event loop is single-threaded and non-preemptive. While a worker is busy executing CPU-intensive `zlib` compression for the `/slow` chunk, it cannot process events for other connections. New requests reaching the busy worker will experience high latency (stuttering) while those reaching the idle worker will be instant.

## 📏 Measure
- **Per-Worker CPU**: Identify through `top` inside the NGINX container.
- **Latency distribution**: Using `autocannon` to measure the split in latency between "lucky" and "unlucky" connections.

## 👀 Observe
- **Process Saturation**: Worker (PID 28) hit **15% - 24% CPU** with just one randomized pinner connection. Worker (PID 29) remained at **0% CPU**.
- **Stutter Effect**: `/fast` requests showed a p50 of **3ms** but a p99 of **102ms** and a Max of **593ms**. This is a **34x - 190x latency penalty** caused solely by worker-level interference and the non-preemptive nature of Gzip compression.

## 🎓 Learn
- **Tail Latency is Process-Bound**: Even with low aggregate CPU, individual synchronous tasks (like Gzip chunks) can stall the entire event loop for over 500ms.
- **Randomness Costs CPU**: Randomized data forces Gzip Level 9 to perform exhaustive pattern searches, maximizing the "stutter" duration.
