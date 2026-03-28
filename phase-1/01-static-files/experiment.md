# 🧪 Experiment 1 — Static File Throughput (Zero-Copy)

## 💡 The Hypothesis
NGINX’s extreme efficiency in serving static files is primarily driven by **Kernel-level optimizations** specifically `sendfile` (zero-copy), rather than its event-driven architecture. By bypassing user-space memory copying, we expect to see a drastic reduction in CPU utilization.

## ⚙️ The Approach: "The Zero-Copy Test"
To quantify the impact of zero-copy, we head-to-head two configurations:
- **`sendfile on;`**: Data stays entirely in the kernel (File → Kernel → Socket).
- **`sendfile off;`**: Data is manually copied (File → Kernel → User-space NGINX → Kernel → Socket).

### The Strategy:
We benchmark both configurations using a **100MB static binary file** and measure how the systems handle the heavy I/O load in terms of CPU context switches and memory pressure.

## 📏 What We Are Measuring

### 1. CPU Efficiency
- **Expected Result**: A 5x+ reduction in CPU usage when `sendfile` is enabled.
- **The Proof**: Does throughput remain stable while CPU drops? If so, the system was wasting compute on redundant copies.

### 2. Zero-Copy Mechanics
- **Normal Flow**: 2 copies + context switches (User/Kernel) per chunk.
- **`sendfile` Flow**: 0 user-space copies. Minimal syscall overhead.

### 3. Memory Consumption
- **Observation**: Monitor memory pressure increases during `sendfile off` due to user-space buffering requirements.

## 🎓 Target Learning
By the end of this experiment, you will understand:
- The difference between **Throughput** (raw speed) and **Efficiency** (cost of speed).
- How **Context Switches** and User-space/Kernel-space boundaries impact high-performance I/O.
- Why the fastest code is often the code that *doesn't run* (eliminating copying).

---

## 🏁 Final Conclusion

**Performance is not just architecture; it is the elimination of redundant work.**

This experiment successfully demonstrated that `sendfile` drastically improves **Efficiency** without necessarily increasing raw **Throughput**. 

### 🧬 Key Findings:
1. **CPU Efficiency Gain**: Enabling `sendfile` reduced CPU usage from **~40% to ~8%** while maintaining the same 2.5 GB/s throughput.
2. **Bottleneck Identification**: Throughput remained capped at ~2.5 GB/s regardless of CPU usage, proving the bottleneck was the **Network / VM Kernel VM (macOS virtualization)**, not the application logic.
3. **Efficiency vs. Speed**: A system can be "fast" (high throughput) but "expensive" (high CPU). `sendfile` is the tool for high-performance optimization at scale.

To build a high-performance system, always leverage **Kernel-level optimizations** before attempting to optimize application-level code.
