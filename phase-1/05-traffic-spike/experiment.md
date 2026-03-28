# 🧪 Experiment 5 — Sudden Traffic Spike (Queue Formation)

## 💡 The Hypothesis
Latency spikes in a distributed system are primarily caused by **Queue Buildup** (Waiting Time), not **CPU Saturation** (Processing Time). A system can experience massive delays even while the CPU remains relatively idle.

## ⚙️ The Approach: "The 10-to-1 Bottleneck"
We have deliberately configured a resource constraint to force a queue to form:
- **The Constraint**: Our Spring Boot backend is limited to exactly **20 worker threads**.
- **The Work**: Each request has a randomized processing delay (sleep) between **50ms and 200ms**.
- **The Spike**: We will use `autocannon` to send **200 concurrent requests** simultaneously.

### The Conflict:
Since only 20 requests can be processed at any single moment, **180 requests are forced to wait in a queue.** The 200th request must wait for multiple "rounds" of 20 to clear before it even begins processing.

## 📏 What We Are Measuring

### 1. The Latency "Gap" (p50 vs. p99)
- **p50 (Median)**: Represents the lucky users who caught a thread early. Should be close to the 125ms average delay.
- **p99 (Tail)**: Represents the unlucky users at the back of the queue. Expect this to be **10x higher** than the p50. This proves that **Waiting Time** has overtaken **Processing Time**.

### 2. CPU Utilization
- Observed via `docker stats`.
- **Expected Result**: CPU usage stays **LOW** (under 20-30%).
- **The Insight**: High Latency + Low CPU = **Concurrency Bottleneck (Queueing).**

## 🎓 Target Learning
By the end of this experiment, you will understand:
- Why **tail latency (p99)** is the true measure of system health.
- Why **Little's Law** dictates that if your arrival rate is higher than your service rate, your queue (and latency) will grow unbounded.
- Why a "Low CPU" metric is a deceptive indicator of a healthy system.

---

## 🏁 Final Conclusion

**Systems do not fail at the average; they fail in the queue.**

This experiment successfully demonstrated that under burst load, **Waiting Time (Queueing)** quickly becomes the dominant component of latency. When the arrival rate exceeded the service rate (200 requests vs. 20 threads), the system was forced to process requests in sequential waves, leading to a **10x increase in latency** despite the **CPU remaining ~90% idle**.

To build a resilient architecture, one must monitor **concurrency limits** and **queue depths** with the same priority as CPU and Memory.
