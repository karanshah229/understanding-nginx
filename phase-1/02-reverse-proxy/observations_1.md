# Docker resources

0. Machine - Mac mini m4 base model
1. CPU - 6 cores
2. Memory - 6GB

## Direct backend (Java)

Peak CPU Usage - 300%
Peak Memory Usage - 280MiB

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 50 -d 20 -p 4 http://localhost:8081/
Running 20s test @ http://localhost:8081/
50 connections with 4 pipelining factor


┌─────────┬───────┬────────┬────────┬────────┬───────────┬───────────┬────────┐
│ Stat    │ 2.5%  │ 50%    │ 97.5%  │ 99%    │ Avg       │ Stdev     │ Max    │
├─────────┼───────┼────────┼────────┼────────┼───────────┼───────────┼────────┤
│ Latency │ 37 ms │ 338 ms │ 663 ms │ 672 ms │ 349.55 ms │ 194.39 ms │ 707 ms │
└─────────┴───────┴────────┴────────┴────────┴───────────┴───────────┴────────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬─────────┬───────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%   │ Avg     │ Stdev     │ Min     │
├───────────┼─────────┼─────────┼─────────┼─────────┼─────────┼───────────┼─────────┤
│ Req/Sec   │ 16,135  │ 16,135  │ 72,767  │ 75,583  │ 65,877  │ 15,312.14 │ 16,130  │
├───────────┼─────────┼─────────┼─────────┼─────────┼─────────┼───────────┼─────────┤
│ Bytes/Sec │ 3.13 MB │ 3.13 MB │ 14.1 MB │ 14.6 MB │ 12.8 MB │ 2.97 MB   │ 3.13 MB │
└───────────┴─────────┴─────────┴─────────┴─────────┴─────────┴───────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

1370k requests in 20.02s, 255 MB read
39 errors (0 timeouts)
```

## Via NGINX

NGINX Peak CPU Usage: 70%
BackendPeak CPU Usage: 110%

NGINX Peak Memory Usage: 18MiB
Backend Peak Memory Usage: 284MiB

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 50 -d 20 -p 4 http://localhost:8080/
Running 20s test @ http://localhost:8080/
50 connections with 4 pipelining factor


┌─────────┬──────┬───────┬───────┬───────┬──────────┬──────────┬───────┐
│ Stat    │ 2.5% │ 50%   │ 97.5% │ 99%   │ Avg      │ Stdev    │ Max   │
├─────────┼──────┼───────┼───────┼───────┼──────────┼──────────┼───────┤
│ Latency │ 8 ms │ 34 ms │ 58 ms │ 62 ms │ 31.97 ms │ 13.88 ms │ 87 ms │
└─────────┴──────┴───────┴───────┴───────┴──────────┴──────────┴───────┘
┌───────────┬────────┬────────┬─────────┬─────────┬───────────┬──────────┬────────┐
│ Stat      │ 1%     │ 2.5%   │ 50%     │ 97.5%   │ Avg       │ Stdev    │ Min    │
├───────────┼────────┼────────┼─────────┼─────────┼───────────┼──────────┼────────┤
│ Req/Sec   │ 3,453  │ 3,453  │ 15,063  │ 16,639  │ 14,513.05 │ 2,609.29 │ 3,452  │
├───────────┼────────┼────────┼─────────┼─────────┼───────────┼──────────┼────────┤
│ Bytes/Sec │ 663 kB │ 663 kB │ 2.89 MB │ 3.19 MB │ 2.79 MB   │ 501 kB   │ 663 kB │
└───────────┴────────┴────────┴─────────┴─────────┴───────────┴──────────┴────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

292k requests in 20.02s, 55.7 MB read
36 errors (36 timeouts)
```

## Observations

The Results Look “Wrong” at First Glance

| Metric      | Direct Backend | Via NGINX   |
| ----------- | -------------- | ----------- |
| Avg Latency | ~350 ms ❌     | ~32 ms ✅   |
| P99 Latency | ~672 ms ❌     | ~62 ms ✅   |
| Throughput  | ~65k RPS ✅    | ~14k RPS ❌ |
| Total Req   | 1.37M          | 292k        |
| Backend CPU | 300% ❌        | 110% ✅     |

👉 This looks contradictory:

- Higher RPS but worse latency (direct)
- Lower RPS but much better latency (NGINX)

#### Root Cause: `-p 4  (HTTP pipelining)`

- Multiple requests are sent without waiting for responses
- Responses are queued per connection
- Latency includes queue wait time

#### Direct backend

- Thread-per-request model (Spring Boot)
- Accepts all incoming requests immediately
- Thread pool gets saturated
- Requests queue up in:
    - thread pools
    - connection buffers

👉 Result:

- High throughput (threads working in parallel)
- BUT huge queueing → high latency (~350ms)
- CPU spikes to 300% (overloaded system)

#### Via NGINX

NGINX acts as a admission control + backpressure layer

It:

- buffers requests
- controls flow to backend
- smooths spikes

👉 Result:

- Lower RPS (intentional throttling)
- MUCH lower latency (~32ms)
- Backend CPU reduced to 110%

### Tradeoff observed

| Aspect           | Direct Backend | Via NGINX |
| ---------------- | -------------- | --------- |
| Throughput (RPS) | Higher         | Lower     |
| Latency          | Higher         | Lower     |
| CPU Efficiency   | Poor           | Better    |
| Stability        | Lower          | Higher    |
| Queue Location   | Backend ❌     | NGINX ✅  |

### Core Insights

1. Latency is dominated by queueing delay
    - Processing time is small—the majority of latency comes from waiting in queues.
2. NGINX acts as a load regulator
    - NGINX is not just a proxy—it enforces backpressure and controls request flow to the backend.
3. More load ≠ better efficiency
    - Direct backend: more load → higher CPU → worse latency
    - Controlled load: consistent CPU → better latency
4. RPS without latency context is misleading
    - High throughput can coexist with terrible user experience
5. Queue placement determines system behavior
    - Direct: queue inside backend → unstable system
    - NGINX: queue at edge → controlled system
6. Backpressure moved to a better system
    - Backpressure shifted from an uncontrolled thread pool to an event-loop-based system (NGINX), improving predictability and latency.

### Conclusion

> Introducing NGINX in front of the backend improved system stability and latency by enforcing controlled request flow.

- Direct backend maximizes throughput but suffers from queue explosion
- NGINX limits concurrency, preventing saturation
- The system trades throughput for latency and stability

### Final Takeaway

> Systems don’t fail due to lack of capacity—they fail due to uncontrolled demand.

NGINX transforms an unstable high-throughput system into a predictable, latency-efficient system by applying backpressure and regulating load.
