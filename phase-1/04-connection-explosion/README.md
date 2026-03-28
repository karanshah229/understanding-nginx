# Experiment 4: Connection Explosion (100k+ Scale)

> [!IMPORTANT]
> **Goal:** Prove NGINX scales connections via event loops (File Descriptors), not threads.
> **Orchestration:** This experiment is managed via Docker Compose to automate multiple-client scaling.

## ⚙️ Orchestrated Setup
1. **Host Limits:** `ulimit -n 200000`
2. **Build and Launch:**
   ```bash
   # Build images and start the infrastructure (Nginx + 4 Clients)
   docker compose up --build -d
   ```
3. **Monitor:** 
   ```bash
   # Track real-time FDs and Internal Connections
   ./scripts/watch.sh
   ```

---

## 🚀 Scaling Strategy: Horizontal Clients
The `compose.yml` launches **four** client containers, each handling **25,000 connections**. This distributes the TCP overhead and keeps the load generators responsive.

### Why 4 clients?
A single `autocannon` process (Node.js) becomes saturated at ~50k connections, causing event loop lag. 4 containers solve this by:
1. **Distributing Load:** Keeping each process under the event loop "lag line."
2. **Expanding Port Capacity:** Each container gets a unique IP, giving a total capacity of **~262,000 ports**.

---

## 🧪 Observations
- **Internal FDs:** `watch.sh` tracks all NGINX process descriptors inside the container.
- **Internal Connections:** Tracks the TCP stack status on the Docker bridge network.
- **Expected Outcome:** FDs should scale 1:1 with connections. CPU should remain stable.

## 🏁 Insights
- **Threads ≠ Concurrency:** 100k connections ≈ handful of worker threads.
- **The Three Ceilings:** Scaling identifies bottlenecks in the App (Nginx), Host (Kernel), and Client (Load Generator).
