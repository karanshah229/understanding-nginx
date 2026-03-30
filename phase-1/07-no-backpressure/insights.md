# 🧠 Final Mental Model: Architecting for Stability

> **"A fast system that crashes is useless. A slow system that survives is a service."**

## Key Insights from Experiment 7

### 1. The Queueing Math (The 4s Wall)
With 2000 concurrent requests and only 50 in-flight threads in the backend:
- Active Queue = 2000 - 50 = 1950.
- Processing batches = 1950 / 50 = 39 batches.
- **Latency = (39 batches * 100ms) + 100ms processing = 4000ms.**
This matches our exact observation. It proves that **latency is a function of queue length**, and because NGINX was configured with "no limits," it allowed the queue to grow until the latency hit an unacceptable wall.

### 2. Backpressure as a Feature
In Experiment 6, we saw backpressure *slow down* the system. In Experiment 7, we saw that *removing* backpressure protection kills the system's responsiveness.
- **NGINX is too nice**: By not limiting `worker_connections`, NGINX acted as a "buffer of death," accepting work it couldn't possibly clear within a reasonable time.
- **Load Shedding**: The primary purpose of `worker_connections` and `limit_req` is to say "No" to the client so that the remaining system can stay responsive.

### 3. Resource Pressure
The NGINX memory usage hit **203MB / 256MB** (80% utilization) just by holding 2000 concurrent sockets and small responses. 
- If the responses had been larger (e.g., 100KB), the 256 `proxy_buffers` of 4k each would have allocated **~1MB per request**, meaning 256MB would have been exhausted within 256 sockets.
- **OOM is the eventual endpoint of any unlimited system.**

### 4. Architect Perspective
As an Architect, your goal is to **constrain the failure domain**.
- **Bound your queues**: Use `worker_connections` to cap the total state NGINX can hold.
- **Fail fast**: Use `proxy_read_timeout` to kill requests that have spent too long in the queue.
- **Isolate**: Using Docker memory limits is a "safety net," but the application (NGINX) should be the first line of defense.
