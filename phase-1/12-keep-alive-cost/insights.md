# 💡 Experiment 12 — Keep-Alive Cost: Key Architectural Insights

> "Idle connections are not free — they are just waiting to be billed."

---

## 📊 Empirical Data

| Metric | Baseline | Peak (52,800 Conns) | Delta |
| :--- | :--- | :--- | :--- |
| **Active Connections** | 1 | 52,806 | +52,805 |
| **NGINX Memory (RSS)** | 508 MiB | 948.4 MiB | **+440.4 MiB** |
| **Total Worker FDs** | 90 | 54,423 | **+54,333** |

### 🧮 The Cost Ratio
- **RAM Cost per Connection**: **~8.7 KB**
- **FD Cost per Connection**: **~1.03 FDs**

## 🏗️ Architectural Lessons

### 1. The Cost of Persistence (RAM)
While an "idle" connection means 0% CPU, it does not mean 0% resources. At scale, the memory overhead of maintaining the TCP state and internal socket buffers becomes a primary capacity constraint.
- NGINX documentation often cites ~3-4KB per connection.
- Our observed **~8.7KB** reflects real-world overhead, including kernel-space TCP buffers and worker process allocations (`worker_processes 6`).
- **The Architect's Calculation**: If each idle connection costs **~8.7 KB**, then **1 Million** idle connections will require **~8.5 GB** of dedicated RAM just for the state, regardless of whether any data is moving.

### 2. File Descriptor Exhaustion is the First Wall
A File Descriptor (FD) is typically the ultimate ceiling for connection scalability before RAM runs out.
- We had to increase `worker_rlimit_nofile` and Docker `ulimits` to **200,000** to sustain 50,000+ connections.
- **Practical Takeaway**: Always set `worker_rlimit_nofile` in your global NGINX config to a value comfortably higher than your expected peak connection count.

### 3. The "Waiting" Connection Lifecycle
Using `stub_status`, you will notice most connections in a production environment are in the **Waiting** state. This is NGINX holding the socket open (Keep-Alive), waiting for the client's next request.
- **Monitoring**: Always monitor the `Waiting` metric in NGINX Status to stay ahead of silent memory growth.
- **Micro-tuning**: Reducing `keepalive_timeout` (e.g., from 65s to 10s) creates a "faster" connection cycle, freeing up RAM and FDs at the cost of more frequent TCP handshakes (increased latency).

---

## 🎓 Final Conclusion

As a software architect, you must treat **Concurrent Connections** as a first-class resource just like CPU or Disk. Design your `keepalive` strategies based on the **Latency vs. Cost** trade-off.

- **High Keep-Alive Timeouts**: Better for user latency (no handshake), higher infrastructure cost (RAM/FDs).
- **Low Keep-Alive Timeouts**: Better for infrastructure density and resource utilization, higher user latency on repeated requests.
