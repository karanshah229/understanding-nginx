## Docker resources

| Metric | NGINX  | Backend |
| ------ | ------ | ------- |
| CPU    | 2      | 2       |
| Memory | 256MiB | 1GiB    |

# Obesrvations - without pipelining

## Direct backend (Java)

| Container | CPU Usage | Memory |
| --------- | --------- | ------ |
| Java      | 215%      | 150MiB |

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 50 -d 20 http://localhost:8081/
Running 20s test @ http://localhost:8081/
50 connections


┌─────────┬──────┬───────┬────────┬────────┬──────────┬──────────┬────────┐
│ Stat    │ 2.5% │ 50%   │ 97.5%  │ 99%    │ Avg      │ Stdev    │ Max    │
├─────────┼──────┼───────┼────────┼────────┼──────────┼──────────┼────────┤
│ Latency │ 7 ms │ 78 ms │ 170 ms │ 183 ms │ 80.66 ms │ 44.84 ms │ 230 ms │
└─────────┴──────┴───────┴────────┴────────┴──────────┴──────────┴────────┘
┌───────────┬────────┬────────┬─────────┬────────┬──────────┬───────────┬────────┐
│ Stat      │ 1%     │ 2.5%   │ 50%     │ 97.5%  │ Avg      │ Stdev     │ Min    │
├───────────┼────────┼────────┼─────────┼────────┼──────────┼───────────┼────────┤
│ Req/Sec   │ 4,219  │ 4,219  │ 34,303  │ 41,311 │ 30,238.3 │ 11,536.53 │ 4,217  │
├───────────┼────────┼────────┼─────────┼────────┼──────────┼───────────┼────────┤
│ Bytes/Sec │ 818 kB │ 818 kB │ 6.64 MB │ 8 MB   │ 5.86 MB  │ 2.23 MB   │ 818 kB │
└───────────┴────────┴────────┴─────────┴────────┴──────────┴───────────┴────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

611k requests in 20.03s, 117 MB read
```

## Via NGINX

| Container | CPU Usage | Memory |
| --------- | --------- | ------ |
| NGINX     | 80%       | 5MiB   |
| Backend   | 117%      | 150MiB |

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 50 -d 20 http://localhost:8080/
Running 20s test @ http://localhost:8080/
50 connections


┌─────────┬──────┬──────┬───────┬───────┬─────────┬─────────┬───────┐
│ Stat    │ 2.5% │ 50%  │ 97.5% │ 99%   │ Avg     │ Stdev   │ Max   │
├─────────┼──────┼──────┼───────┼───────┼─────────┼─────────┼───────┤
│ Latency │ 1 ms │ 7 ms │ 13 ms │ 15 ms │ 7.12 ms │ 3.42 ms │ 32 ms │
└─────────┴──────┴──────┴───────┴───────┴─────────┴─────────┴───────┘
┌───────────┬────────┬────────┬─────────┬────────┬──────────┬──────────┬────────┐
│ Stat      │ 1%     │ 2.5%   │ 50%     │ 97.5%  │ Avg      │ Stdev    │ Min    │
├───────────┼────────┼────────┼─────────┼────────┼──────────┼──────────┼────────┤
│ Req/Sec   │ 1,061  │ 1,061  │ 13,287  │ 15,095 │ 11,721.3 │ 4,542.82 │ 1,061  │
├───────────┼────────┼────────┼─────────┼────────┼──────────┼──────────┼────────┤
│ Bytes/Sec │ 204 kB │ 204 kB │ 2.55 MB │ 2.9 MB │ 2.25 MB  │ 872 kB   │ 204 kB │
└───────────┴────────┴────────┴─────────┴────────┴──────────┴──────────┴────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

235k requests in 20.02s, 45 MB read
```

## Conclusion

> Introducing NGINX in front of the backend significantly reduced latency—not because NGINX is faster, but because it prevented backend saturation by controlling request admission

#### Direct Backend

- Accepts all incoming requests immediately
- Thread pool saturates under concurrency
- Requests queue inside backend
- Queueing delay increases latency (~80ms)

#### Via NGINX

- Acts as an admission control layer
- Limits the rate at which requests reach backend
- Backend operates below saturation
- Minimal queueing → low latency (~7ms)

### Tradeoff Observed

| Aspect                 | Direct | Via NGINX |
| ---------------------- | ------ | --------- |
| Throughput (RPS)       | Higher | Lower     |
| Latency                | Higher | Lower     |
| Backend CPU Efficiency | Poor   | Better    |
| Stability              | Lower  | Higher    |

## Core Insights

1. Latency is dominated by queueing delay, not processing time.
2. NGINX decouples client arrival rate from backend processing rate, preventing unbounded queue growth.
3. NGINX improves system behavior under load by enforcing admission control—not by increasing raw capacity.
