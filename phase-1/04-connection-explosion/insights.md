# Architectural Insights: Connection Explosion (1k → 100k)

Distilled from Experiment 4 — scaling NGINX from 10³ to 10⁵ concurrent connections on a resource-constrained host.

## 1. Bottleneck Migration Across Scale

The dominant bottleneck shifts with each order of magnitude:

- **1k:** NGINX is invisible. 26ms mean latency, zero errors, ~49k RPS. The bottleneck is the application behind it, not the proxy.
- **10k:** Connection management overhead surfaces. Mean latency jumps 9× to 241ms; p99 explodes to 1,436ms. 158 timeouts appear. The proxy layer is now a measurable cost.
- **100k:** The bottleneck leaves NGINX entirely and moves to **host infrastructure** — ephemeral port limits, kernel socket buffers, and load-generator capacity. NGINX itself held 97k file descriptors at peak.

**Takeaway:** At each order of magnitude, the constraining layer changes. Profiling the wrong layer wastes effort.

## 2. Concurrency ≠ Parallelism (Threads vs. FDs)

NGINX held 94,637 concurrent connections using only ~100% CPU across its worker pool. 

- **Verified Observation:** The kernel thread count (LWP) remained **CONSTANT AT 7** (1 Master + 6 Workers) from 1,000 to 100,000 connections. 
- **The Shift:** Each connection cost a **File Descriptor (~2.3 KB RAM)**, not a new thread. 
- **Resource Footprint:** 
    - Baseline memory: 508 MiB (0 connections)
    - Peak memory: 723 MiB (94k connections)
    - Delta: ~2.3 KB per socket.

This is the core advantage of event-driven I/O: connection count scales with memory (FDs), not with CPU scheduling (Threads).

## 3. Three Saturation Boundaries

High-concurrency failure is never a single-point event. Three independent limits were hit in sequence:

1. **Host Network:** macOS ephemeral port range (`49152–65535`) caps a single IP at ~16k outbound connections. Run 1 stalled at exactly 32,699 connections (≈16,350 ports × 2 endpoints), confirming exhaustion. **Mitigation:** moved clients to a private Docker bridge network.
2. **Server Memory:** At 94k connections, NGINX consumed 94% of its 768 MiB container limit. The next allocation failure would trigger OOM-kill. Even "idle" connections have a fixed RAM floor.
3. **Client Event Loop:** All four load-generator containers emitted `TimeoutNegativeWarning` (negative values up to −24,621ms), meaning the Node.js event loop was too saturated to maintain its own timer accuracy. **Mitigation:** horizontal client scaling (4 × 25k instead of 1 × 100k).

**Takeaway:** Capacity planning must account for all three layers — network addressing, server memory, and client fidelity — not just the application under test.

## 4. Observability Must Scale With Architecture

Reaching 100k required two architectural shifts that changed what and how to monitor:

- **Network:** Host-bound `localhost` testing was abandoned for a private Docker bridge, making host-level `netstat` irrelevant. Container-internal FD, connection, and **thread counts** became the source of truth.
- **Metrics:** At 1k, `docker stats` sufficed. At 100k, per-container resource ceilings, per-client error rates, and kernel-level port accounting were all required to diagnose failures.

**Takeaway:** When the infrastructure changes to support scale, the monitoring plane must change with it.
