# 🧪 Experiment 1 — Static File Throughput (sendfile, zero-copy)

---

## 🎯 Goal

Understand why NGINX is extremely efficient at serving static files and how `sendfile` impacts:

- CPU usage
- Throughput
- Memory usage
- Latency

---

## 🧠 Hypothesis

NGINX achieves high throughput with low CPU usage because:

- It uses `sendfile` (zero-copy)
- It avoids unnecessary data copying in user-space
- It leverages kernel-level optimizations

## How does sendfile work ?

Normally, sending a file over a socket looks like this:

1. read() → kernel copies file data → user buffer
2. write() → user buffer copied → kernel socket buffer

That’s two copies + context switches.

With sendfile:

- Data goes file → kernel → socket, staying entirely in kernel space
- No user-space buffer involved
- Fewer copies, fewer syscalls → better performance

---

## ⚙️ Setup

### 1. Project Structure

01-static-files/
├── Dockerfile
├── nginx.conf
├── large.bin

---

### 2. Generate Large File (100MB)

```bash
dd if=/dev/zero of=large.bin bs=1m count=100
```

### 3. NGINX Config (nginx.conf)

#### Version A — sendfile ON

```nginx
  sendfile on;
```

#### Version B — sendfile OFF

```nginx
  sendfile off;
```

### 4. Build and run Dockerfile

docker build -t nginx-static .
docker run -p 8080:8080 nginx-static

### 5. Load Testing

```bash
wrk -t4 -c20 -d20s http://localhost:8080/large.bin
```

### 6. Monitoring Tools

```bash
docker stats
```

or

Docker desktop container stats

### 7. Observations

sendfile ON

- CPU: ~8%
- Memory: ~70MB
- Throughput: ~2.62 GB/s
- Latency: ~745 ms
- Requests/sec: ~26

sendfile OFF

- CPU: ~40%
- Memory: ~100MB
- Throughput: ~2.50 GB/s
- Latency: ~778 ms
- Requests/sec: ~25

### 8. Analysis

1. sendfile reduces CPU usage drastically
    - ~8% → ~40% CPU (5x increase)
    - Throughput remains similar

👉 Conclusion:
sendfile improves efficiency, not necessarily throughput.

2. Throughput is not CPU-bound

Despite increased CPU usage:

    - Throughput remains ~2.5 GB/s

👉 Bottleneck is:

    - Network stack
    - Docker VM (macOS)
    - Kernel limits

3.  Zero-copy matters

    a. Without sendfile

    ```
    Disk → Kernel → User-space (NGINX) → Kernel → Network
    ```

    - Multiple memory copies
    - Higher CPU usage

    b. With sendfile

    ```
    Disk → Kernel → Network
    ```

    - No user-space copying
    - Minimal CPU usage

4.  Latency is dominated by data transfer

    Each request = 100MB
    Latency ~750ms

    👉 Not due to:
    - Event loop
    - CPU

    👉 Due to:
    - Network bandwidth sharing
    - TCP flow control

5.  Low RPS is expected

- Each request is large (100MB)
- 25 req/sec × 100MB ≈ 2.5 GB/sec

👉 System is data-throughput bound, not request-bound

6. Memory usage increases without sendfile
    - More buffering in user-space
    - Extra copies → more memory pressure

## Key Insights

✅ Insight 1 — Performance ≠ just architecture

NGINX performance here is driven by:

> Kernel optimizations (sendfile), not event loop

✅ Insight 2 — Eliminate work, don’t optimize it

> The fastest code is the code that doesn’t run

sendfile avoids copying entirely.

✅ Insight 3 — Identify the real bottleneck

- Not CPU
- Not event loop
- Network / kernel limits

✅ Insight 4 — Efficiency vs Throughput

| Metric     | sendfile ON | sendfile OFF |
| ---------- | ----------- | ------------ |
| CPU        | ✅ Low      | ❌ High      |
| Throughput | ≈ Same      | ≈ Same       |
| Efficiency | ✅ High     | ❌ Low       |
