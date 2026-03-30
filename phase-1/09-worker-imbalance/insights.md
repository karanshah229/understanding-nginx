# 📐 Architectural Insights — Worker Imbalance (Gzip Stress)

## 1. Non-Preemptive CPU Execution
NGINX's event loop is single-threaded and non-preemptive. When a worker process executes a CPU-intensive task like `zlib` compression for Gzip, it **cannot be interrupted** to handle other events until the current task chunk is finished. This creates actual physical bottlenecks at the process level, even if the overall system CPU is idle.

## 2. The "Stutter" and Tail Latency
Our stress test showed that while the median user (p50) experienced **3ms** latency, the "unlucky" users (p99) hit **102ms**, with a maximum spike of **593ms**. This 190-fold increase is the "Stutter Effect." The duration of a single synchronous chunk processing (e.g., one Gzip buffer) sets the **absolute floor** for the maximum possible latency spike on that worker.

## 3. The Deception of Aggregate Metrics
A common mistake in production is monitoring "Total Service CPU." In this experiment, the container CPU was likely only around **10-15%**, yet 50% of the requests were experiencing critical delays. This proves that **Process-Level Observability** (monitoring individual worker PIDs) is the only way to detect "Hot Workers" before they cause customer-facing timeouts.

## 4. Persistent Connection Stickiness (No Work Stealing)
A TCP connection is statically bound to an NGINX worker at the moment it is accepted. NGINX does **not** implement "Work Stealing" (unlike some modern thread-pool schedulers). 
- **The Constraint**: Worker 2, even at 0% CPU, has no visibility into the event queue of Worker 1. 
- **Epoll Isolation**: Each worker maintains its own private `epoll` instance. Once a socket's File Descriptor (FD) is registered with Worker 1's `epoll` set, only Worker 1 receives kernel notifications for that connection.
- **Memory Boundary**: NGINX uses a "Shared-Nothing" architecture. All connection state (buffers, Gzip dictionaries, SSL state) resides in the **private heap** of the worker process. Migrating a connection would require expensive Inter-Process Communication (IPC) to transfer this state.
- **The Result**: New events for a connection stuck on Worker 1 must wait for Worker 1's event loop to cycle. There is no architectural mechanism for an idle worker to "offload" or "help" a busy neighbor.

## 5. Resource Partitioning (Cores vs. Workers)
This experiment demonstrates why matching `worker_processes` to the number of physical CPU cores is critical. In our test, by allocating `cpus: 2` in Docker, we ensure that Worker 2 remains responsive even while Worker 1 is pinning its own core at 100%. If we had only 1 CPU core for 2 workers, the OS scheduler would time-slice them, and you wouldn't see the clear delta in p99 latency between "lucky" and "unlucky" requests.

## 6. Mitigating Worker Bottlenecks in Production
- **Offload Compression**: Use a CDN or a separate hardware layer for Gzip/SSL if possible.
- **Tune Keep-Alive**: Use `keepalive_requests` (e.g., 1000) to force periodic connection resets, which physically forces re-distribution across workers.
- **L7 Load Balancing**: If using an external load balancer (like HAProxy or ALB), use "Least Request" or "Least Conn" logic to avoid sending new traffic to a worker that is already pinned by a heavy streaming client.
