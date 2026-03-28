## Docker resources

| Metric | NGINX  | Backend |
| ------ | ------ | ------- |
| CPU    | 2      | 2       |
| Memory | 256MiB | 1GiB    |

# Obesrvations - without pipelining

## Direct backend (Slow Java app + max 20 threads)

| Container | CPU Usage | Memory |
| --------- | --------- | ------ |
| Java      | 25%       | 180MiB |

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 1000 -d 20 http://localhost:8081/
Running 20s test @ http://localhost:8081/
1000 connections

running [=========           ] 45%(node:64096) TimeoutNegativeWarning: -1 is a negative number.
Timeout duration was set to 1.
(Use `node --trace-warnings ...` to show where the warning was created)

┌─────────┬────────┬─────────┬─────────┬─────────┬─────────┬────────────┬─────────┐
│ Stat    │ 2.5%   │ 50%     │ 97.5%   │ 99%     │ Avg     │ Stdev      │ Max     │
├─────────┼────────┼─────────┼─────────┼─────────┼─────────┼────────────┼─────────┤
│ Latency │ 414 ms │ 5379 ms │ 8622 ms │ 8636 ms │ 4990 ms │ 2629.09 ms │ 9988 ms │
└─────────┴────────┴─────────┴─────────┴─────────┴─────────┴────────────┴─────────┘
┌───────────┬─────┬──────┬─────────┬─────────┬─────────┬─────────┬───────┐
│ Stat      │ 1%  │ 2.5% │ 50%     │ 97.5%   │ Avg     │ Stdev   │ Min   │
├───────────┼─────┼──────┼─────────┼─────────┼─────────┼─────────┼───────┤
│ Req/Sec   │ 0   │ 0    │ 54      │ 100     │ 50.55   │ 45.65   │ 1     │
├───────────┼─────┼──────┼─────────┼─────────┼─────────┼─────────┼───────┤
│ Bytes/Sec │ 0 B │ 0 B  │ 10.5 kB │ 19.4 kB │ 9.81 kB │ 8.86 kB │ 194 B │
└───────────┴─────┴──────┴─────────┴─────────┴─────────┴─────────┴───────┘

Req/Bytes counts sampled once per second.
# of samples: 20

3k requests in 20.08s, 196 kB read
1k errors (1k timeouts)
```

## Via NGINX (Rate limits)

| Container | CPU Usage | Memory |
| --------- | --------- | ------ |
| NGINX     | 70%       | 7MiB   |
| Backend   | 5%        | 170MiB |

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 1000 -d 20 http://localhost:8080/
Running 20s test @ http://localhost:8080/
1000 connections


┌─────────┬───────┬────────┬─────────┬─────────┬────────────┬────────────┬──────────┐
│ Stat    │ 2.5%  │ 50%    │ 97.5%   │ 99%     │ Avg        │ Stdev      │ Max      │
├─────────┼───────┼────────┼─────────┼─────────┼────────────┼────────────┼──────────┤
│ Latency │ 38 ms │ 825 ms │ 4815 ms │ 5791 ms │ 1310.54 ms │ 1312.14 ms │ 10542 ms │
└─────────┴───────┴────────┴─────────┴─────────┴────────────┴────────────┴──────────┘
┌───────────┬────────┬────────┬─────────┬─────────┬──────────┬──────────┬────────┐
│ Stat      │ 1%     │ 2.5%   │ 50%     │ 97.5%   │ Avg      │ Stdev    │ Min    │
├───────────┼────────┼────────┼─────────┼─────────┼──────────┼──────────┼────────┤
│ Req/Sec   │ 16,911 │ 16,911 │ 21,695  │ 26,735  │ 21,775.2 │ 2,877.18 │ 16,898 │
├───────────┼────────┼────────┼─────────┼─────────┼──────────┼──────────┼────────┤
│ Bytes/Sec │ 6.3 MB │ 6.3 MB │ 8.09 MB │ 9.99 MB │ 8.13 MB  │ 1.08 MB  │ 6.3 MB │
└───────────┴────────┴────────┴─────────┴─────────┴──────────┴──────────┴────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

1975 2xx responses, 433513 non 2xx responses
504k requests in 20.05s, 163 MB read
```

## Conclusion: NGINX vs. Systemic Thread Pool Collapse

**1. The Hard Capacity Floor**

- **Result:** With backend threads capped at 20 (theoretical max: **100 RPS**), NGINX sustained **~98 RPS**, while the direct path collapsed to **~50 RPS**.
- **Analysis:** In the direct path, the system entered "Collapse Mode"—where thread contention and timeouts reduced effective throughput by 50% below theoretical capacity. NGINX preserves backend efficiency by ensuring it only receives manageable traffic.

**2. Load Shedding as a Stability Pattern**

- **Observation:** NGINX rejected **~99.6%** of incoming traffic (~433k requests) to maintain an average latency of **~1.3s**, compared to **~5s+** in the direct path.
- **Takeaway:** Capacity ≠ Traffic. Load shedding is a critical stability pattern, not a failure. Immediately rejecting requests at the edge is mathematically superior to allowing an unbounded backend queue to explode latency for all users.

**3. Resource Preservation: CPU Decoupling**

- **Result:** Backend CPU dropped from **25% to 5%** under identical load when shielded by NGINX.
- **Conclusion:** By pushing rejection logic to the proxy, the application layer is freed from the overhead of managing a doomed queue. This validates that while thread pools define hard capacity, the traffic control layer defines systemic stability.
