# Reverse Proxy Experiments — Unified Insights

> **Objective:** Understand NGINX's behavior as a reverse proxy across different backend architectures, concurrency levels, and protection strategies.

> **Infrastructure:** Docker containers on Mac Mini M4. NGINX: 2 CPU / 256MiB. Backend: 2 CPU / 1GiB. Load tool: `autocannon`.

---

## The Three Experiments

| #   | Backend                             | Key Variable                              | NGINX Config                         | Runs |
| --- | ----------------------------------- | ----------------------------------------- | ------------------------------------ | ---- |
| 001 | Spring Boot (fast)                  | Backend architecture (thread-per-request) | Bare proxy                           | 3    |
| 002 | Node.js Fastify (fast)              | Backend architecture (event loop)         | Bare proxy                           | 1    |
| 003 | Spring Boot + `Thread.sleep(200ms)` | Simulated latency + thread cap            | Proxy → rate limiting → `limit_conn` | 4    |

---

## Part 1: What Does NGINX Actually Do to a Backend?

### Insight 1 — NGINX is a Resource Optimizer, Not a Throughput Booster

|             | Direct (Java) | Via NGINX |
| ----------- | ------------- | --------- |
| Latency     | ~80ms         | **~7ms**  |
| Throughput  | ~30k RPS      | ~12k RPS  |
| Backend CPU | 215%          | **117%**  |

> _001 / observations_2 — 50 connections, no pipelining_

NGINX **halved backend CPU** and **reduced latency by 11×** at the cost of lower raw throughput. The backend doesn't get faster — it gets **less overwhelmed**.

**Why:** NGINX pools connections to the upstream, absorbs TCP handshake churn, and meters request arrival rate. The backend processes work in batches rather than drowning in concurrent thread contention.

---

### Insight 2 — Latency is Dominated by Queueing, Not Processing

With HTTP pipelining (`-p 4`), the direct Java backend hit **~65k RPS** but with **~350ms latency**. Via NGINX: **~14k RPS** but only **~32ms latency**.

> _001 / observations_1 — 50 connections, 4x pipelining_

The paradox: **higher throughput = worse latency**. The direct path accepts all requests immediately, saturating its thread pool. Requests queue inside the JVM. NGINX throttles admission, so requests that reach the backend experience minimal wait.

> **Queueing is the dominant latency component, not processing time.**

---

## Part 2: Does Backend Architecture Change the Equation?

### Insight 3 — Efficient Backends Make Raw NGINX Overhead More Visible

|             | Direct (Node) | Via NGINX    |
| ----------- | ------------- | ------------ |
| Avg Latency | 139ms         | **~8s**      |
| Throughput  | ~33k RPS      | ~2.2k RPS    |
| Errors      | 12k timeouts  | 100 timeouts |
| Backend CPU | 120%          | **50%**      |

> _002 / observations_1 — 10,000 connections, no NGINX limits_

Node.js already uses an event loop — similar to NGINX's own model. Under extreme concurrency (10k), adding a bare NGINX **made things worse**: latency went from 139ms to ~8 seconds due to queue amplification.

**Key distinction:**

- **Thread-per-request backends (Java):** NGINX provides admission control the backend lacks
- **Event-loop backends (Node):** NGINX without limits adds a redundant queuing layer

> NGINX is not universally beneficial. Its value is **proportional to the backend's inability to self-regulate under overload.**

---

### Insight 4 — Multiple NGINX Instances ≠ More Capacity

> _001 / observations_3 — theoretical analysis_

Adding more NGINX proxies in front of the same backend does **not** increase throughput. It fragments the admission queue, removes centralized control, and can **increase** tail latency through uncoordinated load.

Multiple proxies help only for: TLS termination at scale, geographic distribution, or handling more client-side connections.

---

## Part 3: What Happens When the Backend is Genuinely Slow?

### Insight 5 — Without Limits, NGINX Creates an Invisible Latency Bomb

|             | Direct (slow Java) | Via NGINX (no limits) |
| ----------- | ------------------ | --------------------- |
| Avg Latency | ~1s                | **~9s**               |
| P99 Latency | ~1s                | **~18s**              |
| Throughput  | ~980 RPS           | ~967 RPS              |

> _003 / observations_2 — 1000 connections_

Throughput is **identical**. But latency diverges by **9×**. NGINX's event loop accepted all 1000 connections and queued them against a 200ms-per-request backend. The backend never knew it was overloaded. **Queue Amplification** — the proxy hides backpressure, converting it into unbounded tail latency.

> **Throughput parity ≠ system health. Always check latency percentiles.**

---

### Insight 6 — Rate Limiting Flips the Model from "Wait Forever" to "Fail Fast"

|                | NGINX (no limits) | NGINX (rate limited) |
| -------------- | ----------------- | -------------------- |
| Avg Latency    | ~9s               | **~822ms**           |
| Successful RPS | ~967              | **~430**             |
| Rejection Rate | 0%                | **~98%**             |
| NGINX CPU      | 35%               | **100%**             |

> _003 / observations_2 vs observations_3 — 1000 connections_

Enabling `limit_conn` dropped latency by **11×** by rejecting excess traffic at the edge. NGINX CPU hit 100% doing high-velocity 5xx rejections — a task it handles orders of magnitude more efficiently than any application server. The system shifted from **"Saturated"** (all users suffer) to **"Controlled Overload"** (admitted users get predictable service).

> **Rate limiting protects capacity; it does not increase it.**

---

### Insight 7 — Edge Protection Prevents Thread Pool Collapse

|                 | Direct (20 threads) | Via NGINX + limits (20 threads) |
| --------------- | ------------------- | ------------------------------- |
| Theoretical Max | 100 RPS             | 100 RPS                         |
| Actual RPS      | **~50**             | **~98**                         |
| Avg Latency     | ~5s                 | **~1.3s**                       |
| Timeouts        | 1,000               | 0                               |
| Backend CPU     | 25%                 | **5%**                          |

> _003 / observations_4 — 1000 connections, backend max 20 threads_

Without protection, thread contention and timeout storms reduced effective throughput to **50% of theoretical max**. With NGINX rate limiting and connection limits, the backend operated at **98% of theoretical max** with zero timeouts.

> **Thread pools define hard capacity. The traffic control layer defines whether you actually reach it.**

---

## The Progression

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   Fast backend     → NGINX = resource optimizer (CPU ↓, latency ↓)         │
│                                                                             │
│   Efficient backend (Node) → bare NGINX = overhead (latency ↑)            │
│                                                                             │
│   Slow backend     → bare NGINX = latency bomb (queue amplification)       │
│                                                                             │
│   + Rate limiting  → NGINX = active gatekeeper (fail-fast at edge)         │
│                                                                             │
│   + Thread cap     → NGINX = collapse preventer (preserves max capacity)   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Design Principles Validated

| #   | Principle                                                                                                                                                                         | Validated By |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| 1   | **Queue placement determines system behavior.** Backend queues are uncontrolled; edge queues are manageable.                                                                      | 001, 003     |
| 2   | **An unconstrained proxy is worse than no proxy under saturation.** It hides backpressure and amplifies tail latency.                                                             | 002, 003     |
| 3   | **Fail fast > wait forever.** Immediate rejection preserves SLA for admitted traffic.                                                                                             | 003          |
| 4   | **NGINX's value is inversely proportional to the backend's ability to self-regulate.** Thread-per-request models benefit most; event-loop models benefit least from a bare proxy. | 001 vs 002   |
| 5   | **Throughput is not a health metric.** Two systems can show identical RPS while one is 9× worse on latency.                                                                       | 003          |
| 6   | **Thread pools are hard ceilings, but only reachable under controlled admission.** Uncontrolled traffic erodes even theoretical capacity.                                         | 003          |
| 7   | **Push rejection logic to the edge.** Proxies reject at negligible cost vs. application servers.                                                                                  | 003          |
