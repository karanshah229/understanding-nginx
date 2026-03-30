# 🧪 Experiment 7 — Remove Backpressure Controls

## 🎯 Objective
Understand failure behavior. Observe what happens when NGINX is forced to handle unlimited concurrent requests with a slow backend and massive buffers.

## ⚙️ Setup
- **Backend (Spring Boot)**: Artificially delayed by **100ms** per request.
- **NGINX (Reverse Proxy)**: 
    - `worker_connections 65535` (Unlimited)
    - `proxy_buffering on` (Buffer overhead)
    - `proxy_read_timeout 600s` (No load shedding)
- **Monitoring**: 
    - `docker stats` (Resource consumption)
    - `nginx_status` (Active connections)
    - `autocannon` (Performance & Errors)

## 💡 Hypothesis
The system will become unstable under load. Without limits, NGINX will consume memory linearly for every active connection until it either crashes (OOM) or the kernel starts dropping packets due to socket exhaustion.

## 📏 Measure
- **Active Connections**: How many concurrent sockets are open?
- **NGINX Memory Usage**: Does it hit the 256MB limit?
- **Errors**: At what point do 502/504/Connection Reset errors appear?

## 👀 Observe
- **Active Connections**: Stabilized at exactly **2001** (2000 from autocannon + 1 status check).
- **Latency Wall**: Average latency hit **~4000ms** (4 seconds).
- **Throughput**: Stabilized at **~487 RPS**, which perfectly matches the backend's theoretical capacity (50 threads * 10 req/sec).
- **Resource Usage**: NGINX memory plateaued at **203MB / 256MB**. It did not OOM because the small response size didn't exhaust the proxy buffers, but it was dangerously close.
- **State**: Almost all connections were in the `Writing` state in NGINX, meaning they were queued up waiting for the backend.

## 🎓 Learn
- **Queueing Math is Inescapable**: With 2000 concurrent requests and 50 backend threads, every request waits for ~39 batches (3.9s), leading to the 4s latency wall.
- **Load shedding is critical**: In this experiment, NGINX was "too nice." By not limiting connections, it allowed a massive queue to form, turning a 100ms service into a 4s service.
- **Stability requires limits**: Without the 256MB Docker limit, NGINX could have potentially swallowed even more connections until the host machine ran out of memory.
