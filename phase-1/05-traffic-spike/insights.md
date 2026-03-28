# 🧠 Experiment 5 — Architectural Insights

## 🎯 Hypothesis Validation: **CONFIRMED**

The data confirms that **Queueing Delay (Wait Time)** completely dominates latency under burst load, with **near-zero correlation to CPU saturation**.

| Metric          | Phase 1 (Baseline) | Phase 2 (Burst) | Delta / Ratio      |
| :-------------- | :----------------- | :-------------- | :----------------- |
| **Concurrency** | 10                 | 200             | 20x                |
| **p50 Latency** | 205 ms             | 2,030 ms        | **~10x Increase**  |
| **Backend CPU** | 6.35%              | 10.21%          | **~1.6x Increase** |

---

## 🏗️ Insights

### 1. The Concurrency "Wall" (Thread Starvation)

The system hit a hard wall at 20 concurrent requests due to the **Thread Pool limit**.

- **The Math**: With 200 concurrent requests and 20 workers, requests move in 10-batch waves.
- **The Result**: 9 out of 10 requests are merely "waiting" for a thread. This explains why latency scaled linearly with the degree of over-subscription ($10\text{ waves} \times 200\text{ms} = 2000\text{ms}$), while CPU remained idle.

### 2. The Deception of "Healthy" CPU Metrics

A Staff Engineer must recognize that **Low CPU ≠ System Health**.

- The backend remained 90% idle (CPU-wise) while user experience was 10x slower.
- Traditional "Autoscaling on CPU" would have failed here. The system was **saturated** at the thread-pool layer, but **under-utilized** at the compute layer.

### 3. Little’s Law in the Real World ($L = \lambda W$)

When the arrival rate ($\lambda$) spiked to 200, and the system capacity ($L$) remained fixed at 20 threads, the time in the system ($W$) was _forced_ to expand.

- **Insight**: In a bursts, latency is the **overflow valve** for fixed capacity. If you don't bound the queue, the wait time grows unbounded.

### 4. Architectural Mitigation: Load Shedding vs. Waiting

Making a user wait 2 seconds for a 200ms task is often worse than failing fast.

- **Recommendation**: Implement **Admission Control** (e.g., NGINX `max_conns` or Spring `server.tomcat.accept-count`) to reject requests once the optimal queue depth is exceeded.
- **Staff Insight**: Better to serve 20 users fast and fail 180 (503), than to serve all 200 users miserably slow.

---

## 🏁 Final Conclusion

**Systems do not fail at the average; they fail in the queue.**
True system observability must monitor **Thread Pool saturation** and **Queue Depth** alongside CPU/Memory to detect this type of failure.
