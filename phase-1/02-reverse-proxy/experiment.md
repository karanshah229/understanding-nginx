# 🧪 Experiment 2 — Reverse Proxy & Admission Control

## 💡 The Core Hypothesis
NGINX’s value as a reverse proxy primarily lies in its role as an **Admission Control** layer. Its effectiveness is inversely proportional to the backend’s ability to self-regulate. 

NGINX stabilizes blocking backends (Thread-per-request) by metering admission, but can add redundant overhead to non-blocking backends (Event Loop) unless protective policies (limits) are applied.

---

## 🔬 Sub-Experiment 2.1: The Java Model (Blocking I/O)
### **The Goal**: 
Observe how NGINX interacts with backends that are constrained by fixed thread pools (Spring Boot).

### **Key Findings**: 
- **Resource Optimization**: NGINX **halved backend CPU** (215% → 117%) and reduced latency by **11×** at the cost of some raw throughput.
- **Queue Movement**: By throttling admission, NGINX moves the "waiting line" from the saturated JVM thread pool to the lightweight NGINX proxy layer. This decouples processing from contention.

---

## 🔬 Sub-Experiment 2.2: The Node.js Model (Non-Blocking I/O)
### **The Goal**: 
Observe NGINX in front of a backend that uses an identical architectural pattern (Fastify Event Loop).

### **Key Findings**:
- **Queue Amplification**: Under extreme concurrency (10k), a bare NGINX proxy actually increased latency from **139ms to 8 seconds**.
- **Insight**: For event-driven backends, NGINX's value isn't in "admission control" (since the backend already handles concurrency well) but in **Edge Features** (TLS, caching, security).

---

## 🔬 Sub-Experiment 2.3: The "Latency Bomb" & Protection
### **The Goal**: 
Simulate a slow backend (200ms delay) and observe the mandatory nature of rate/connection limiting.

### **Key Findings**:
- **"Wait Forever" (Unprotected)**: Without limits, NGINX hides the backend's slowness, creating a "Latency Bomb" where users wait up to 18 seconds for a 200ms task.
- **"Fail Fast" (Protected)**: By enabling `limit_conn` and `limit_req`, latency dropped from **9s to 822ms**. 
- **Staff Insight**: Rate limiting protects **admitted user experience**. It doesn't increase capacity, but it ensures that the admitted users receive predictable service.

---

## 🎓 Unified Target Learnings
- **Throughput ≠ Health**: Two systems can have identical RPS while one is 9× slower on latency.
- **Design for Failure**: Admission control (Load Shedding) at the edge is mandatory for system stability.
- **Know Your Backend**: Deploy NGINX for *resource optimization* on Java-style stacks and for *service protection* on Node-style stacks.

---

## 🏁 Final Conclusion

**The traffic control layer defines whether you actually reach your theoretical capacity.**

This suite of experiments proved that thread pools define a hard ceiling, but uncontrolled traffic erodes that ceiling via contention and timeouts. NGINX preserves system integrity by pushing rejection logic to the edge, where it is orders of magnitude cheaper to execute than in the application layer.
