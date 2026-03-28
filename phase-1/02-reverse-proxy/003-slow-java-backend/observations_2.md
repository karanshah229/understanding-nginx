## Docker resources

| Metric | NGINX  | Backend |
| ------ | ------ | ------- |
| CPU    | 2      | 2       |
| Memory | 256MiB | 1GiB    |

# Obesrvations - without pipelining

## Direct backend (Slow Java app)

| Container | CPU Usage | Memory |
| --------- | --------- | ------ |
| Java      | 40%       | 220MiB |

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 1000 -d 20 http://localhost:8081/
Running 20s test @ http://localhost:8081/
1000 connections


┌─────────┬────────┬─────────┬─────────┬─────────┬───────────┬───────────┬─────────┐
│ Stat    │ 2.5%   │ 50%     │ 97.5%   │ 99%     │ Avg       │ Stdev     │ Max     │
├─────────┼────────┼─────────┼─────────┼─────────┼───────────┼───────────┼─────────┤
│ Latency │ 642 ms │ 1012 ms │ 1030 ms │ 1039 ms │ 994.56 ms │ 103.77 ms │ 1223 ms │
└─────────┴────────┴─────────┴─────────┴─────────┴───────────┴───────────┴─────────┘
┌───────────┬────────┬────────┬────────┬────────┬────────┬─────────┬────────┐
│ Stat      │ 1%     │ 2.5%   │ 50%    │ 97.5%  │ Avg    │ Stdev   │ Min    │
├───────────┼────────┼────────┼────────┼────────┼────────┼─────────┼────────┤
│ Req/Sec   │ 800    │ 800    │ 1,000  │ 1,000  │ 980    │ 52.18   │ 800    │
├───────────┼────────┼────────┼────────┼────────┼────────┼─────────┼────────┤
│ Bytes/Sec │ 155 kB │ 155 kB │ 194 kB │ 194 kB │ 190 kB │ 10.1 kB │ 155 kB │
└───────────┴────────┴────────┴────────┴────────┴────────┴─────────┴────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

21k requests in 20.08s, 3.8 MB read
```

## Via NGINX

| Container | CPU Usage | Memory |
| --------- | --------- | ------ |
| NGINX     | 35%       | 5MiB   |
| Backend   | 30%       | 220MiB |

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 1000 -d 20 http://localhost:8080/
Running 20s test @ http://localhost:8080/
1000 connections


┌─────────┬────────┬─────────┬──────────┬──────────┬────────────┬────────────┬──────────┐
│ Stat    │ 2.5%   │ 50%     │ 97.5%    │ 99%      │ Avg        │ Stdev      │ Max      │
├─────────┼────────┼─────────┼──────────┼──────────┼────────────┼────────────┼──────────┤
│ Latency │ 693 ms │ 9004 ms │ 17455 ms │ 17964 ms │ 9003.56 ms │ 5027.16 ms │ 18964 ms │
└─────────┴────────┴─────────┴──────────┴──────────┴────────────┴────────────┴──────────┘
┌───────────┬────────┬────────┬────────┬────────┬────────┬─────────┬────────┐
│ Stat      │ 1%     │ 2.5%   │ 50%    │ 97.5%  │ Avg    │ Stdev   │ Min    │
├───────────┼────────┼────────┼────────┼────────┼────────┼─────────┼────────┤
│ Req/Sec   │ 740    │ 740    │ 985    │ 1,006  │ 967.5  │ 59.3    │ 740    │
├───────────┼────────┼────────┼────────┼────────┼────────┼─────────┼────────┤
│ Bytes/Sec │ 142 kB │ 142 kB │ 189 kB │ 193 kB │ 186 kB │ 11.4 kB │ 142 kB │
└───────────┴────────┴────────┴────────┴────────┴────────┴─────────┴────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

184k requests in 20.04s, 3.72 MB read
```

## Conclusion: NGINX Behavior under Systemic Saturation

**1. The Overload Paradox: Latency Explosion**

- **Result:** Under high concurrency (1000), NGINX latency surged to **~9 seconds** (with P99s hitting **~18 seconds**), compared to a stable ~1s in the direct-to-backend path.
- **Analysis:** This demonstrates **Queue Amplification**. NGINX's event-driven model accepts connections cheaply but, without limits, it buffers requests that the backend cannot yet process. This transforms natural backpressure into an unbounded upstream queue.

**2. Throughput Deception**

- **Observation:** Throughput remained parity (~970-980 RPS) across both paths.
- **Takeaway:** Throughput is not a proxy for system health. While the backend was fully utilized in both cases, the NGINX path traded predictable degradation for catastrophic tail latency.

**3. Architectural Insight: The "Buffer" Liability**

- **Conclusion:** In a distributed system, efficiency without constraints is a liability. NGINX's ability to "hide" backpressure leads to a "slow death" scenario. **"Fail Fast"** (connection rejection) is architecturally superior to "Wait Forever" (unlabeled queueing).
