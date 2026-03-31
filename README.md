# 🚀 Understanding NGINX: A 4-Phase Mastery Curriculum

This repository documents a systematic journey from observing NGINX as a "black box" to deconstructing its C source code. This is not a "getting started" guide; it is a curriculum for **Staff-level Traffic Engineering.**

---

## 🏗️ The Curriculum Roadmap

| Phase | Title | Focus | Status |
| :--- | :--- | :--- | :--- |
| **0** | **The Mental Model** | Theoretical shift from Threads to Events | ✅ Complete |
| **1** | **Observation (Black Box)** | 14 Experiments on systemic behavior | ✅ Complete |
| **2** | **Orchestration (Production)** | Defensive Architecture & Hardening | ⏳ Next |
| **3** | **Evaluation (Competition)** | HAProxy, Envoy, & Strategic Tradeoffs | 📅 Planned |
| **4** | **Deep Dive (Construct/Deconstruct)** | C-Level Engineering: Build → Verify in Source | 📅 Planned |

---

## 🧠 Phase 0: The Mental Model
**Objective**: Internalize the shift from preemptive multitasking (threads) to cooperative multitasking (event loops).

Before touching code, you must destroy the "Thread-per-Request" intuition. Application servers (Tomcat) scale linearly with RAM/Threads; NGINX scales logarithmically by eliminating them.

### 🎭 The Cooperative Model
- **Non-blocking I/O**: Why `read()` shouldn't wait.
- **Multiplexing (`epoll`/`kqueue`)**: How one thread "watches" 100,000 sockets.
- **L1/L2 Cache Locality**: Why the single worker model dominates multi-threaded designs by avoiding CPU context-switch churn.

---

## 🧪 Phase 1: Observation (Black Box)
**Objective**: Build a "gut feel" for system failure signatures through empirical load testing.

In this phase, we treated NGINX as a black box and ran 14 controlled experiments. We learned exactly how the system visually degrades when it hits various physical walls (RAM, CPU, FDs, Kernel Queues).

> [!TIP]
> Read the complete analysis: **[Index of Architectural Insights](./phase-1/insights.md)**

---

## 🚀 Phase 2: Orchestration (Production Hardening)
**Objective**: Transition from "making it work" to "defensive edge architecture."

Before cracking open the source code, we focus on the high-level architectural patterns required for zero-downtime, global-scale systems. This phase covers the "Staff Engineer" decisions made at the edge.

### 🛡️ Hardening & Orchestration Patterns:
- **High Availability & Anycast**: VRRP failover across NGINX clusters.
- **Edge Patterns & CDNs**: Hierarchical caching, stale-while-revalidate, and purging at the edge.
- **Traffic Shaping**: Rate limiting (Leaky Bucket) and Admission Control.
- **The Hardening Lab**: 8 scenarios including **Limping Nodes**, **Thundering Herds**, and **Slow Clients**.

> [!TIP]
> Read the Phase 2 Guide: **[Orchestration Master Reference](./phase-2/README.md)**

---

## 🆚 Phase 3: Evaluation (Strategic Decision Making)
**Objective**: Understand the competitive landscape and when NGINX is the *wrong* choice.

Professional architects must know when to switch tools. We head-to-head NGINX against modern alternatives to understand where each shines and where they fail.

### 📊 Strategic Comparisons:
- **NGINX vs HAProxy**: Pure L4/L7 performance vs L7 application-layer flexibility.
- **NGINX vs Envoy**: Sidecars, Service Mesh, and the shift toward the xDS API control plane.
- **L4 Admission Control**: Implementing IPVS/LVS in front of NGINX clusters for massive aggregate capacity.

> [!TIP]
> Read the Phase 3 Guide: **[Evaluation Master Reference](./phase-3/README.md)**

---

## 🏗️ Phase 4: Deep Dive (Construction & Deconstruction)
**Objective**: Build it in C, then verify it in the NGINX Source.

For each sub-system, you will first implement a "Mini" version in C to understand the architectural challenge, and then immediately deconstruct the NGINX C source for that same module.

### 🔬 The Learning Loop:
1.  **Construct**: Build a custom server/proxy sub-system in C.
2.  **Measure**: Benchmark your implementation against Phase 1 baselines.
3.  **Deconstruct**: Read the corresponding NGINX C source code to see how the industry standard handles that specific problem.

> [!TIP]
> Read the Phase 4 Guide: **[Deep Dive Master Reference](./phase-4/README.md)**

---

## 🏁 The Architectural Outcome
By the end of Phase 4, you will be able to look at any system-wide latency spike and say: **"The queue is here. This is why. This is the kernel/config knob to fix it."**
