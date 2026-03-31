# 🆚 Phase 3: Evaluation (Strategic Decision Making)

Welcome to the "Evaluation" phase. In Phase 2, you hardened NGINX for production. In Phase 3, you step back to the **Strategic Architecture Layer.** 

Being a Principal Architect is not about knowing one tool perfectly; it is about knowing when that tool is the **wrong choice.** You will head-to-head NGINX against its primary competitors to understand the fundamental trade-offs in modern traffic engineering.

---

## 🏛️ The Philosophy: "Right Tool for the Job"
NGINX is often called the "Swiss Army Knife" of the web. However, specialized tools like HAProxy often provide better raw performance, and modern engines like Envoy provide better dynamic programmability. 

Success in this phase means you can defend an architectural choice between NGINX, HAProxy, and Envoy based on **empirical data**, not just popularity.

---

## 🔬 Project 3.1: NGINX vs HAProxy (The Specialized Scalpel)
**Objective**: Understand the performance delta between a general-purpose web server (NGINX) and a specialized load balancer (HAProxy).

### 🎓 Core Concepts:
- **HAProxy's Single-Process Model**: Why HAProxy often beats NGINX in pure L4/L7 proxying.
- **Protocol Depth**: HAProxy's advanced health checking vs NGINX's simpler upstream logic.

### 💡 The Hypothesis:
HAProxy will exhibit lower p99 latency and higher aggregate throughput for pure proxying because it does not carry the "Static File" or "Module" overhead of NGINX.

---

## 🔬 Project 3.2: NGINX vs Envoy (The Sidecar Engine)
**Objective**: Understand the shift from "Static Edge" to "Dynamic Service Mesh."

### 🎓 Core Concepts:
- **Control Plane vs Data Plane**: Understanding how Envoy receives configuration (LDS, RDS, CDS, EDS) without ever dropping a connection.
- **Sidecar Proxying**: Why Envoy's performance characteristics are optimized for "East-West" traffic inside a mesh.

### 💡 The Hypothesis:
Envoy will maintain 100% request success rates during a high-frequency configuration churn (100 updates/min), while NGINX's reload mechanism may cause transient latency spikes.

---

## 🔬 Project 3.3: NGINX vs Apache (The Preemptive Thread Legacy)
**Objective**: Validate the "Event Driven" revolution by benchmarking it against the "Threaded" legacy.

---

## 🔬 Project 3.4: L4 Admission Control (IPVS/LVS)
**Objective**: Scale NGINX horizontally by offloading early-stage TCP termination to the kernel.

---

## 🏁 The Phase 3 Evaluation
By the end of this phase, you are no longer a "Developer" using a proxy. You are a **Systems Architect.** You can design an ingress stack that combines the speed of L4 (IPVS), the specialization of HAProxy, and the flexibility of NGINX.

**Next Step**: Move to [**Phase 4: Deep Dive**](../phase-4/README.md) for the final deconstruction of the source code.
