# 🧪 Experiment 4 — Connection Explosion (1k → 100k)

## 💡 The Hypothesis
NGINX’s non-blocking, event-driven architecture can handle massive concurrency (100,000+ connections) with a **constant and minimal thread count**, scaling primarily with **File Descriptors (FDs)** and memory, rather than CPU context-switching.

## ⚙️ The Approach: "Scaling by Orders of Magnitude"
To prove the efficiency of the event loop, we scale the system across three distinct orders of magnitude:
- **1k**: Baseline performance (identifying the application bottleneck).
- **10k**: Observing the first signs of connection management overhead.
- **100k**: Stressing the OS kernel and reaching the physical limits of the host.

### The Strategy:
We bypass host-level ephemeral port exhaustion (which caps at ~16k) by using a **private Docker bridge network** and horizontally scaling our load-generator clients (4 containers × 25k connections each).

## 📏 What We Are Measuring

### 1. File Descriptor (FD) Growth
- **Expected Result**: Linear growth. Each connection costs exactly one FD (~2.3 KB of RAM).
- **The Proof**: Going from 1k to 100k connections should show a 100x increase in FDs, but NOT a 100x increase in threads.

### 2. Kernel Thread Count (LWP)
- Observed via `measure-threads.sh`.
- **Expected Result**: Constant at **7** (1 Master + 6 Workers) regardless of connection count.
- **The Insight**: This proves that NGINX does **Concurrency** via the event loop, not via OS-level **Parallelism** (threads).

### 3. Memory Footprint
- **Calculated Cost**: Total RAM Delta / Total Connections.
- **Goal**: Demonstrate that "idle" connections are extremely cheap (~2-3 KB each).

## 🎓 Target Learning
By the end of this experiment, you will understand:
- Why **Concurrency ≠ Parallelism**.
- How the **C10k problem** was solved by moving away from thread-per-connection.
- How to identify "invisible" infrastructure bottlenecks (ephemeral ports, kernel buffers).

---

## 🏁 Final Conclusion

**Scaling is not about more threads; it’s about managing state without them.**

This experiment successfully demonstrated that NGINX can hold **94,637 concurrent connections** while maintaining a constant pool of **7 threads**. 

### 🧬 Key Findings:
1. **Bottleneck Migration**: At 1k, the bottleneck was the backend; at 100k, it became the **Host Network** (ephemeral ports) and **Client Fidelity** (Node.js event loop saturation).
2. **Resource Efficiency**: Each connection cost only **2.3 KB of RAM**, allowing a massive footprint within a modest 768 MiB container.
3. **The Limit**: We reached **94% Memory Utilization** and **100% CPU (Event Management)** simultaneously, proving that at this scale, the cost of managing the "event state" itself becomes the new compute bottleneck.

To build at this scale, one must move beyond application tuning and begin **Kernel and Network Layer engineering**.
