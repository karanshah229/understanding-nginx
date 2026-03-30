# 🧠 Key Insights — Experiment 8: CPU-bound Backend

> "NGINX is a master of managing connections, but it is not a worker engine. It can keep the door open, but it cannot speed up the factory."

### 1. Bottleneck Differentiation
- **I/O Bound (Exp 6)**: The backend is waiting. You see high latency with **LOW** CPU on both NGINX and the Backend.
- **CPU Bound (Exp 8)**: The backend is working. 
  - **The Observation**: Moving from **C=20 to C=30** connection concurrency resulted in **0% throughput gain** but a **47% latency penalty**.
  - **The Resource**: Backend was pinned at **49.16%** (limit matched), while NGINX was idle at **1.6%**.

### 2. The Fallacy of NGINX Tuning
When the bottleneck is CPU-bound in the backend, tuning NGINX (worker_processes, buffers, timeouts) is effectively useless. You are optimizing the *admission* of requests when the *processing* capacity is already saturated. No amount of proxy tuning can reduce the overhead of the Fibonacci calculation.

### 3. Throughput Ceiling & Queueing Delay
This experiment is a textbook demonstration of the **Throughput Ceiling**. Once the 0.5-core CPU was 100% busy, it could only produce ~78 RPS. 
- Adding more concurrent connections (from 20 to 30) didn't increase work done.
- It only increased the **Queueing Delay**, inflating average latency from 260ms to 382ms.

### 4. Architect's "Low CPU" Myth
A "Healthy" NGINX CPU (< 2%) often hides a catastrophic backend failure. Monitoring must be end-to-end to identify where the "Work" is actually happening and where the "Wait" is occurring. If you only look at NGINX metrics, the system looks fine; if you look at the Backend, the system is on fire.
