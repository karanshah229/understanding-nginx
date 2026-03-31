# Phase 1: Index of Architectural Insights

This document distills the empirical findings from all 14 Phase 1 experiments into concise architectural principles. 

---

## 1. System Efficiency & Bottlenecks

### The CPU Illusion
* **Observation**: High latency + low CPU = Queueing bottleneck. Systems fail in the queue before they fail at the processor. — *[Experiment 5](./05-traffic-spike)*
* **Observation**: During OS-level socket exhaustion, CPU drops to near zero while failure rates spike. — *[Experiment 10](./10-fd-limit)*
* **Conclusion**: Stop monitoring just CPU "saturation". Start monitoring resource "starvation" (File Descriptors, Kernel Queues, Ephemeral Ports).

### Connection Costs
* **Observation**: Idle connections aren't free. "Keep-Alive" sockets predictably cost ~8.7 KB of RAM each. — *[Experiment 12](./12-keep-alive-cost)*
* **Observation**: A reverse proxy requires two File Descriptors (Client + Upstream) per connection. Your actual network capacity is half your OS limit. — *[Experiment 10](./10-fd-limit)*
* **Conclusion**: High-concurrency scaling must account for the cumulative memory weight of idle, waiting sockets.

### The True Cost of I/O
* **Observation**: Kernel-level zero-copy (`sendfile`) reduces CPU usage by up to 5x without increasing raw throughput. — *[Experiment 1](./01-static-files)*
* **Conclusion**: Raw throughput ≠ efficiency. The most scalable systems eliminate redundant memory copies rather than executing code faster.

---

## 2. Event-Driven Mechanics

### Concurrency vs. Parallelism
* **Observation**: NGINX safely holds ~100k TCP connections using a small, constant pool of kernel threads. — *[Experiment 4](./04-connection-explosion)*
* **Observation**: A single CPU-heavy task (e.g., maximum Gzip compression) pauses the entire non-preemptive event loop, punishing all other connections with up to 190x latency spikes. — *[Experiment 9](./09-worker-imbalance)*
* **Conclusion**: Workers scale parallelism (CPU) — *[Experiment 3](./03-single-vs-multiple-workers)*. The Event Loop scales concurrency (Connections). Do not mix heavy synchronous compute tasks with event loops.

### State Management Limits
* **Observation**: At extreme scale (100k+ connections), NGINX saturates CPU cycles purely on event management overhead, even without doing application work. — *[Experiment 4](./04-connection-explosion)*
* **Conclusion**: Event loops are state brokers, not compute engines.

---

## 3. Threat Modeling & Traffic Control

### The Physics of Backpressure
* **Observation**: Without edge limits, backend slowness propagates infinitely upstream. It consumes proxy memory and turns rapid requests into massive latency bombs. — *[Experiment 6](./06-slow-backend)* & *[Experiment 7](./07-no-backpressure)*
* **Conclusion**: Backpressure naturally flows backward. The slowest node dictates the entire downstream system's capacity.

### Admission Control
* **Observation**: NGINX successfully protects blocking backends (e.g., Java Thread-per-request) by holding the waiting line at the edge, preventing thread exhaustion. — *[Experiment 2](./02-reverse-proxy)*
* **Observation**: Conversely, failing to cap NGINX queue depths in front of non-blocking backends (e.g., Node.js) causes massive latency amplification. — *[Experiment 2](./02-reverse-proxy)*
* **Conclusion**: Deploy proxies to *shield* synchronous backends. Deploy proxies strictly for *edge features* (TLS, caching) on asynchronous backends. Ensure limits align with the backend type.

### TLS Overhead
* **Observation**: TLS handshakes cause massive up-front CPU spikes (3x cost of HTTP). Ongoing symmetric payload encryption is computationally cheap. — *[Experiment 13](./13-tls-overhead)*
* **Conclusion**: Capacity plan for connection *churn rate* (handshakes), not just aggregate payload size.

---

## 4. The Topography of Failure

### The Failure Signatures
* **The OS Kernel (`somaxconn`)**: Drops early SYN packets. Causes massive TCP-retry latency. Application metrics appear perfectly healthy. — *[Experiment 11](./11-kernel-queue-limits)*
* **The Proxy Layer**: Emits clean HTTP 503 errors. Prevents downstream collapse and guarantees fast service for admitted users. — *[Experiment 14](./14-queue-location)*
* **The Application Layer (Threads)**: Suffers thread exhaustion. Creates a "Wait Forever" state where performance degrades universally for all users. — *[Experiment 14](./14-queue-location)*
* **Conclusion**: The location of the bottleneck dictates exactly *how* a system visibly fails. True observability maps the external failure mode to the right layer's internal telemetry. — *[Experiment 14](./14-queue-location)*
