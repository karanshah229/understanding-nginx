## Docker resources

| Metric | NGINX  | Backend |
| ------ | ------ | ------- |
| CPU    | 2      | 2       |
| Memory | 256MiB | 1GiB    |

# Obesrvations - without pipelining

## Direct backend (Slow Java app)

| Container | CPU Usage | Memory |
| --------- | --------- | ------ |
| Java      | 25%       | 120MiB |

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 50 -d 20 http://localhost:8081/
Running 20s test @ http://localhost:8081/
50 connections


┌─────────┬────────┬────────┬────────┬────────┬───────────┬─────────┬────────┐
│ Stat    │ 2.5%   │ 50%    │ 97.5%  │ 99%    │ Avg       │ Stdev   │ Max    │
├─────────┼────────┼────────┼────────┼────────┼───────────┼─────────┼────────┤
│ Latency │ 203 ms │ 207 ms │ 219 ms │ 227 ms │ 207.68 ms │ 4.66 ms │ 259 ms │
└─────────┴────────┴────────┴────────┴────────┴───────────┴─────────┴────────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%   │ Avg     │ Stdev   │ Min     │
├───────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Req/Sec   │ 200     │ 200     │ 250     │ 250     │ 240     │ 17.82   │ 200     │
├───────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 38.8 kB │ 38.8 kB │ 48.5 kB │ 48.5 kB │ 46.6 kB │ 3.45 kB │ 38.8 kB │
└───────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

5k requests in 20.03s, 931 kB read
```

## Via NGINX

| Container | CPU Usage | Memory |
| --------- | --------- | ------ |
| NGINX     | 3%        | 4MiB   |
| Backend   | 8%        | 140MiB |

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 50 -d 20 http://localhost:8080/
Running 20s test @ http://localhost:8080/
50 connections


┌─────────┬────────┬────────┬────────┬────────┬───────────┬─────────┬────────┐
│ Stat    │ 2.5%   │ 50%    │ 97.5%  │ 99%    │ Avg       │ Stdev   │ Max    │
├─────────┼────────┼────────┼────────┼────────┼───────────┼─────────┼────────┤
│ Latency │ 202 ms │ 206 ms │ 216 ms │ 221 ms │ 206.54 ms │ 3.37 ms │ 226 ms │
└─────────┴────────┴────────┴────────┴────────┴───────────┴─────────┴────────┘
┌───────────┬─────────┬─────────┬───────┬───────┬─────────┬─────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%   │ 97.5% │ Avg     │ Stdev   │ Min     │
├───────────┼─────────┼─────────┼───────┼───────┼─────────┼─────────┼─────────┤
│ Req/Sec   │ 200     │ 200     │ 250   │ 250   │ 240     │ 17.3    │ 200     │
├───────────┼─────────┼─────────┼───────┼───────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 38.4 kB │ 38.4 kB │ 48 kB │ 48 kB │ 46.1 kB │ 3.32 kB │ 38.4 kB │
└───────────┴─────────┴─────────┴───────┴───────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

5k requests in 20.03s, 922 kB read
```

## Conclusion: NGINX Impact on Latency-Bound Upstreams

**1. Latency & Throughput Baseline**

- **Result:** Latency overhead is sub-millisecond (~1ms delta) and statistically insignificant.
- **Takeaway:** At 200ms+ backend latency, the proxy is effectively "zero-cost." The bottleneck is strictly the `Thread.sleep()` in the upstream service.

**2. Resource Optimizer: The "Shock Absorber" Effect**

- **Observation:** Backend CPU dropped from **25% to 8%** when proxied.
- **Analysis:** NGINX handles the heavy lifting of TCP handshake churn and connection management. By maintaining persistent keep-alive pools to the upstream and buffering requests, it eliminates thread contention and context switching on the JVM.
- **Principle:** A reverse proxy is a load optimizer, not just a router. It increases the "efficiency per request" of the backend.

**3. Architectural Validation**

- **Conclusion:** The standard `Client -> NGINX -> App` pattern is validated not for latency reduction, but for **resource decoupling**. The proxy shields the app server from connection-level overhead, allowing it to focus strictly on business logic execution.
