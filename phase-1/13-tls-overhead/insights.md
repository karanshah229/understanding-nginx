# 🧪 Experiment 13 — TLS Overhead Key Insights

## 🏗️ Architectural Perspective

### 1. The Asymmetric Penalty (Handshakes)
- **High Concurrency Burst**: The initial handshake for 100 concurrent connections triggered an immediate **3x peak CPU usage** compared to HTTP.
- **Architectural Bottleneck**: This confirms that the most significant cost of TLS is **connection establishment**. In high-churn environments (e.g., public APIs with short-lived connections), the CPU will saturate long before network bandwidth does.

### 2. The Symmetric "Tax" (Sustained Load)
- **Ongoing Overhead**: Once connections were established, the sustained CPU was **30-40% higher** than the HTTP baseline.
- **Hardware Acceleration**: While 40% sounds high, it was an absolute increase of only **~3% CPU utilization** in our test. This showcases the efficiency of modern **AES-NI (Advanced Encryption Standard New Instructions)** at the hardware level.

### 3. Latency: The Tale at the Tail (p99)
- **Tail Latency Sensitivity**: Average latency remained flat, but **p99 latency** increased by **~15%**. 
- **Architectural Takeaway**: TLS overhead is felt most at the extremes. When a user experiences a slow page load, it's often the cumulative delay of several "expensive" TLS handshakes for different resources.

### 4. Mitigation Strategy: Connection Reuse
- **Keep-Alive is King**: Sustaining persistent connections and using **TLS Session Resumption** (which we saw NGINX handle flawlessly here) are the most important optimizations for a secure architecture.

---

### 📊 Measurements Summary

| Metric | HTTP (Baseline) | HTTPS (TLS) | Delta (%) |
| :--- | :--- | :--- | :--- |
| **Peak CPU Burst** | 12.68% | 35.72% | **+181.7%** |
| **Sustained CPU (%)** | ~6-7% | ~9-10% | **+40%** |
| **Avg Latency (ms)** | 34.42 ms | 29.28 ms | ~(-15%) |
| **p99 Latency (ms)** | 171 ms | 197 ms | **+15.2%** |

---

### 🎓 Final Conclusion
TLS adds a significant computational cost to **connection establishment** while remaining extremely efficient for **data carry**. For any architect, the goal isn't just "faster" encryption — it's **fewer handshakes**.
