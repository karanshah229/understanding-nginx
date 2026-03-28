# Architectural Insights: NGINX Workers vs. Event Loops

This article summarizes key observations from load testing an NGINX reverse proxy in front of a Spring Boot service, focusing on how worker processes and event loops influence system behavior under load.

## 1. Concurrency vs. Parallelism

NGINX’s architecture separates _connection concurrency_ from _CPU parallelism_:

- **Concurrency (Event Loop):** Each worker uses a non-blocking event loop to multiplex thousands of connections on a single core.
- **Parallelism (Workers):** Additional workers allow NGINX to utilize multiple CPU cores and increase total throughput.

> **Key Insight:** Worker count primarily scales compute capacity (requests/sec), not the number of concurrent connections the system can hold open.

---

## 2. Where Queueing Actually Happens

NGINX is often described as “not queueing,” but a more precise statement is:

> NGINX minimizes application-level queueing by relying on event-driven I/O, while deferring most contention to downstream systems and the kernel.

In practice, latency accumulation typically follows this path:

```
Client → TCP backlog → NGINX (event loop + buffers) → App thread pool → DB pool
```

- NGINX introduces minimal overhead when proxying fast upstreams.
- However, queueing can still occur in:
    - kernel accept queues
    - connection limits (`worker_connections`)
    - upstream wait time and buffering

> **Key Insight:** NGINX surfaces downstream saturation rather than masking it.

---

## 3. Bottleneck Hierarchy in Real Systems

In a typical web stack, NGINX is rarely the first component to fail.

- **Backend services** (e.g., Spring Boot) are constrained by:
    - thread pools
    - blocking I/O
    - database connection limits
- These introduce explicit queueing and backpressure.

During testing, the backend consistently saturated and degraded before NGINX showed signs of resource exhaustion.

> **Key Insight:** Load testing through NGINX measures _system capacity_, not just proxy capacity. Isolating NGINX is necessary for accurate proxy benchmarking.

---

## 4. System Behavior Under Load

The system exhibited three predictable phases:

1. 🟢 **Healthy:** Low latency, linear throughput growth
2. 🟡 **Saturation:** Throughput plateaus, latency increases (queueing begins)
3. 🔴 **Collapse:** Errors and timeouts spike as bounded resources are exhausted

These transitions align with standard queueing dynamics and are typically driven by backend limits rather than the proxy layer.

---

## 5. Refined Mental Model

- **NGINX:** Event-driven, highly efficient at connection multiplexing, with low per-request overhead. It can still be constrained by CPU, I/O, or system limits under extreme load.
- **Backend Systems:** Thread-bound, explicitly queueing, and usually the first point of saturation.

> ⚡ **Bottom Line**  
> NGINX doesn’t eliminate queueing—it shifts it. By keeping the proxy layer efficient, it makes downstream bottlenecks visible, measurable, and ultimately the limiting factor in system performance.
