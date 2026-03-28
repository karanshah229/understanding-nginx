# Key Insights: NGINX Reverse Proxy with a Slow Backend

> **Setup:** Java backend with `Thread.sleep(200ms)` behind NGINX reverse proxy.
> All tests run via `autocannon` with Docker resource limits: 2 CPU / 256MiB (NGINX), 2 CPU / 1GiB (Backend).

---

## 1. At Low Concurrency, NGINX is a Free Lunch

| Metric | Direct | Via NGINX |
| --- | --- | --- |
| Avg Latency | 207ms | 206ms |
| Throughput | 240 RPS | 240 RPS |
| Backend CPU | 25% | **8%** |

> *Source: observations_1 — 50 concurrent connections*

**Insight:** The proxy adds sub-millisecond overhead. Its real value is **resource decoupling** — by pooling connections and absorbing TCP handshake churn, it cuts backend CPU by **3×** while delivering identical throughput and latency.

**Principle:** A reverse proxy is a **load optimizer**, not just a router.

---

## 2. At High Concurrency Without Limits, NGINX Becomes a Liability

| Metric | Direct | Via NGINX |
| --- | --- | --- |
| Avg Latency | ~1s | **~9s** |
| P99 Latency | ~1s | **~18s** |
| Throughput | ~980 RPS | ~967 RPS |

> *Source: observations_2 — 1000 concurrent connections, no rate limiting*

**Insight:** Throughput is identical, but latency diverges catastrophically. NGINX's event loop accepts connections cheaply and queues them unboundedly when the backend is saturated. This is **Queue Amplification** — the proxy transforms natural backpressure into invisible, unbounded queuing.

**Anti-pattern:** Throughput parity masks a critically degraded system. **Throughput ≠ Health.**

---

## 3. Rate Limiting Restores Predictability via "Fail Fast"

| Metric | NGINX (no limits) | NGINX (rate limited) |
| --- | --- | --- |
| Avg Latency | ~9s | **~822ms** |
| P99 Latency | ~18s | **~5.8s** |
| Successful RPS | ~967 | **~430** |
| Rejection Rate | 0% | **~98%** |
| NGINX CPU | 35% | **100%** |
| Backend CPU | 30% | **30%** |

> *Source: observations_2 vs observations_3 — 1000 concurrent connections*

**Insight:** Rate limiting trades availability for predictability. The system shifts from **"Saturated" (unusable)** to **"Controlled Overload" (stable for admitted traffic)**. NGINX absorbs 100% CPU doing high-velocity rejections — a task it handles orders of magnitude more efficiently than an application server.

**Principle:** Rate limiting **protects** capacity; it does not **increase** it.

---

## 4. NGINX Prevents Thread Pool Collapse

| Metric | Direct (20 threads) | Via NGINX + Rate Limit (20 threads) |
| --- | --- | --- |
| Theoretical Max RPS | 100 | 100 |
| Observed RPS | **~50** | **~98** |
| Avg Latency | **~5s** | ~1.3s |
| Timeouts | 1,000 | 0 |
| Backend CPU | 25% | **5%** |

> *Source: observations_4 — 1000 concurrent connections, backend max 20 threads*

**Insight:** Without protection, the direct path hits **"Collapse Mode"** — thread contention and timeout storms slash throughput to **50% of theoretical capacity**. NGINX preserves the backend's performance envelope, sustaining **98% of theoretical max** by routing only manageable traffic.

**Principle:** Thread pools define **hard capacity**. The traffic control layer defines **systemic stability**.

---

## The Progression (TL;DR)

```
Low Load         → Proxy = free resource optimizer
High Load        → Proxy without limits = latency bomb (queue amplification)
+ Rate Limiting  → Proxy = active gatekeeper (fail-fast at the edge)
+ Thread Cap     → Proxy = collapse preventer (preserves theoretical capacity)
```

## Design Takeaways

| # | Takeaway |
| --- | --- |
| 1 | **Always configure upstream limits.** An unconstrained proxy is worse than no proxy under saturation. |
| 2 | **Fail fast > wait forever.** Immediate rejection is superior to unbounded queueing for overall system health. |
| 3 | **Push rejection logic to the edge.** Proxies handle rejection at negligible cost vs. application servers. |
| 4 | **Monitor latency percentiles, not just throughput.** Throughput can mask catastrophic user experience degradation. |
| 5 | **Thread pools are hard ceilings.** Without edge protection, contention erodes even theoretical capacity. |
