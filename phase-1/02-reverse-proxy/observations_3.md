## Q1: If backend is Node.js instead of Spring Boot, do we still need NGINX?

**Initial Thought:**  
Node.js has an event loop → may reduce need for NGINX.

**Correct Understanding:**  
Node.js improves _internal concurrency_ but does **not replace NGINX**.

### What Node.js Handles

- Efficient concurrent connections (no thread-per-request)
- Non-blocking I/O
- Reduced internal queueing vs Spring Boot

### What Node.js Does NOT Handle

- **Admission control** (no early rejection or throttling)
- **Overload protection** (queue still grows if traffic exceeds capacity)
- **CPU-heavy tasks** (event loop can block entire server)
- **Network optimizations** (TLS, buffering, slow clients, connection reuse)

### Key Insight

Node removes thread overhead, **but not overload or queueing problems**.

### Final Answer

Node.js improves concurrency inside the app, but NGINX is still needed for:

- Controlling incoming traffic
- Handling slow clients
- Providing system-level stability and protection

---

## Q2: Multiple NGINX servers with same backend capacity

**Initial Thought:**  
No effect since backend capacity is unchanged.

**Correct Understanding:**  
Throughput stays the same, but **system behavior changes**.

### What Stays the Same

- Backend CPU and max throughput (RPS)

### What Changes

1. **Higher ingress pressure**
    - Multiple NGINX instances send more traffic to backend
    - Risk of overwhelming backend

2. **Loss of centralized control**
    - Each NGINX acts independently
    - No global awareness → possible overload

3. **Fragmented queueing**
    - Single queue → multiple uncoordinated queues

4. **Higher latency variability**
    - Uneven load distribution
    - Worse tail latency (p99)

### When Multiple NGINX Helps

- Handling more client connections
- TLS termination at scale
- Geographic distribution

### What It Does NOT Improve

- Backend bottlenecks
- Core system capacity

### Final Answer

Multiple NGINX instances do not increase throughput, but can:

- Increase load pressure
- Reduce effectiveness of admission control
- Cause instability and worse latency if not coordinated

---

## Final Mental Model

### 1. Application Layer (Node / Spring)

- Execution model
- CPU usage
- Internal queueing

### 2. Proxy Layer (NGINX)

- Admission control
- Buffering
- Connection management

### 3. System Level

- End-to-end stability
- Queue placement
- Latency distribution
