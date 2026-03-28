# Q: If backend is Node.js instead of Spring Boot, do we still need NGINX?

### Initial Thought

Node.js has an event loop → may reduce need for NGINX.

## Experiment

## Docker resources

| Metric | NGINX  | Backend |
| ------ | ------ | ------- |
| CPU    | 2      | 2       |
| Memory | 256MiB | 1GiB    |

# Obesrvations - without pipelining

## Direct backend (Node)

| Container | CPU Usage | Memory |
| --------- | --------- | ------ |
| Backend   | 120%      | 450MiB |

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 10000 -d 20 http://localhost:3000/
Running 20s test @ http://localhost:3000/
10000 connections

running [=========           ] 45%(node:48534) TimeoutNegativeWarning: -1 is a negative number.
Timeout duration was set to 1.
(Use `node --trace-warnings ...` to show where the warning was created)

┌─────────┬───────┬───────┬────────┬─────────┬───────────┬───────────┬─────────┐
│ Stat    │ 2.5%  │ 50%   │ 97.5%  │ 99%     │ Avg       │ Stdev     │ Max     │
├─────────┼───────┼───────┼────────┼─────────┼───────────┼───────────┼─────────┤
│ Latency │ 15 ms │ 62 ms │ 317 ms │ 2012 ms │ 139.39 ms │ 308.75 ms │ 9005 ms │
└─────────┴───────┴───────┴────────┴─────────┴───────────┴───────────┴─────────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬───────────┬─────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%   │ Avg       │ Stdev   │ Min     │
├───────────┼─────────┼─────────┼─────────┼─────────┼───────────┼─────────┼─────────┤
│ Req/Sec   │ 8,863   │ 8,863   │ 34,655  │ 41,055  │ 32,722.32 │ 7,920.5 │ 8,859   │
├───────────┼─────────┼─────────┼─────────┼─────────┼───────────┼─────────┼─────────┤
│ Bytes/Sec │ 1.67 MB │ 1.67 MB │ 6.51 MB │ 7.72 MB │ 6.15 MB   │ 1.49 MB │ 1.67 MB │
└───────────┴─────────┴─────────┴─────────┴─────────┴───────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 19

643k requests in 20.93s, 117 MB read
12k errors (12k timeouts)
```

## Via NGINX

| Container | CPU Usage | Memory |
| --------- | --------- | ------ |
| NGINX     | 40%       | 10MiB  |
| Backend   | 50%       | 60MiB  |

```
➜  02-reverse-proxy git:(main) ✗ autocannon -c 10000 -d 20 http://localhost:8080/
Running 20s test @ http://localhost:8080/
10000 connections


┌─────────┬───────┬─────────┬──────────┬──────────┬────────────┬────────────┬──────────┐
│ Stat    │ 2.5%  │ 50%     │ 97.5%    │ 99%      │ Avg        │ Stdev      │ Max      │
├─────────┼───────┼─────────┼──────────┼──────────┼────────────┼────────────┼──────────┤
│ Latency │ 36 ms │ 7754 ms │ 16953 ms │ 17928 ms │ 7992.02 ms │ 4894.62 ms │ 20185 ms │
└─────────┴───────┴─────────┴──────────┴──────────┴────────────┴────────────┴──────────┘
┌───────────┬────────┬────────┬────────┬────────┬──────────┬────────┬────────┐
│ Stat      │ 1%     │ 2.5%   │ 50%    │ 97.5%  │ Avg      │ Stdev  │ Min    │
├───────────┼────────┼────────┼────────┼────────┼──────────┼────────┼────────┤
│ Req/Sec   │ 668    │ 668    │ 2,093  │ 3,725  │ 2,159.31 │ 646.73 │ 668    │
├───────────┼────────┼────────┼────────┼────────┼──────────┼────────┼────────┤
│ Bytes/Sec │ 124 kB │ 124 kB │ 389 kB │ 693 kB │ 402 kB   │ 120 kB │ 124 kB │
└───────────┴────────┴────────┴────────┴────────┴──────────┴────────┴────────┘

Req/Bytes counts sampled once per second.
# of samples: 20

43175 2xx responses, 3 non 2xx responses
178k requests in 20.32s, 8.03 MB read
100 errors (100 timeouts)
```

## Conclusion

Node.js improves how efficiently work is processed, but NGINX controls how much work enters the system.

### What Node.js Handles

- Efficient concurrent connections (no thread-per-request)
- Non-blocking I/O
- High throughput under moderate load

### What Node.js Does NOT Handle

- **Overload management** → requests still queue when arrival rate > processing rate
- **Admission control** → no built-in mechanism to reject excess traffic early
- **Backpressure at system boundary** → event loop queues can still grow
- **CPU-heavy tasks** → event loop can block entire server
- **Edge concerns** → no built-in TLS termination, buffering, slow client handling, or connection reuse

### Key Insight

> When the backend is already efficient (Node.js), adding NGINX without limits adds overhead and can reduce performance.
>
> Under extreme load, NGINX does not eliminate overload—it shifts queueing upstream, often increasing latency unless paired with rejection policies.

### Final Answer

Node.js reduces internal inefficiencies, but does not remove the need for load shaping.

> NGINX is not required for performance in front of Node.js—it is required for controlling overload behavior.

In production systems, NGINX is used to:

- Controlling incoming traffic
- Protect the backend from unbounded queueing
- Handle edge concerns (TLS, buffering, slow clients)
