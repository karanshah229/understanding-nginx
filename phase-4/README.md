# 🏗️ Phase 4: Deep Dive (Construction & Deconstruction)

Welcome to the technical core of the curriculum. In Phase 4, we remove the magic by **reimplementing the sub-systems of NGINX in C**, then immediately **verifying our intuition against the NGINX C source code.**

This "Build-then-Verify" approach ensures you understand the architectural intent and the low-level implementation reality.

---

## 🏛️ The Learning Loop: Build → Measure → Deconstruct
Each project in this phase follows a 3-step cycle:
1.  **Construct**: Implement the sub-system from scratch in **C** using raw Linux syscalls (`socket`, `epoll`, `fork`).
2.  **Measure**: Benchmark your implementation against the Phase 1 baselines.
3.  **Deconstruct**: Read the corresponding NGINX C source code to see how the industry standard handles the same problem.

---

## 🔬 Project 4.1: The Worker Lifecycle (Process vs. Thread)
**Objective**: Witness the physical limits of OS-level concurrency and how NGINX manages its worker fleet.

### 🏗️ Build: The Blocking Baseline
Build a server in C that spawns a new OS Thread (using `pthread_create`) or Process (using `fork`) for every incoming connection. 

### 🔍 Deconstruct: NGINX Worker Management
Read the NGINX source for process management.
*   **Target File**: `src/os/unix/ngx_process_cycle.c`
*   **Target Logic**: How the Master process forks Workers.

---

## 🔬 Project 4.2: The Multiplexed Engine (Event Loop)
**Objective**: Implement the NGINX "secret sauce"—the non-blocking, single-threaded event loop.

### 🏗️ Build: The Manual `epoll` Loop
Build a C server that handles 10,000 connections on a single thread using the `epoll` system call.

### 🔍 Deconstruct: The NGINX Event Heartbeat
Read the NGINX source for event handling.
*   **Target File**: `src/event/ngx_event.c` and `src/event/modules/ngx_epoll_module.c`.

---

## 🔬 Project 4.3: The Asynchronous Proxy State Machine
**Objective**: Bridge two separate socket streams within a single event loop.

### 🔍 Deconstruct: The Upstream Module
Read the NGINX source for proxying.
*   **Target File**: `src/http/ngx_http_upstream.c`.

---

## 🔬 Project 4.4: Flow Control & Memory Management
**Objective**: Implement manual backpressure and hierarchical memory pools.

### 🔍 Deconstruct: NGINX Memory & Buffer Logic
Read the NGINX source for memory pools and buffers.
*   **Target File**: `src/core/ngx_palloc.c` and `src/core/ngx_buf.c`.

---

## 🏁 The Phase 4 Evaluation
By completing Phase 4, you have reached the **"Staff Engineer"** peak. You no longer "guess" how NGINX works; you know exactly what the kernel and the C code are doing.

**Final Architectural Outcome**: You can design an ingress stack that combines the speed of L4 (IPVS), the specialization of HAProxy, and the flexibility of NGINX.
