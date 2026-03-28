1st actual run. Observations:

## 📊 Summary of Scale Comparison (1k → 10k → 100k)

| Metric | 1k Test | 10k Test | 100k Test (Peak) |
| :--- | :--- | :--- | :--- |
| **Concurrent Conns** | 1,000 | 10,000 | 94,637 (Actual Peak) |
| **Max FDs** | 1,139 | 10,151 | 97,066 |
| **Mean Latency** | 26.5 ms | 241 ms | ~17.5 s (Saturated) |
| **Errors** | 0 | 158 (timeouts) | ~47k (Saturation) |
| **Nginx CPU** | 129% (RPS Load) | 117% (Burst) | 100.15% (Event Management) |
| **Nginx Mem** | 517 MiB | 585 MiB | 723 MiB (94% Utilization) |

---

## Before starting load test

FDs: 137
Connections: 0

docker stats
faa9e55072d2 nginx 1.23% 508.3MiB / 1GiB 49.64% 1.17kB / 126B 0B / 12.3kB 7

## 1k load test

➜ phase-1 git:(main) ✗ autocannon -c 1000 -d 30 http://localhost:8080/
Running 30s test @ http://localhost:8080/
1000 connections

┌─────────┬───────┬───────┬───────┬───────┬──────────┬──────────┬─────────┐
│ Stat │ 2.5% │ 50% │ 97.5% │ 99% │ Avg │ Stdev │ Max │
├─────────┼───────┼───────┼───────┼───────┼──────────┼──────────┼─────────┤
│ Latency │ 11 ms │ 22 ms │ 51 ms │ 61 ms │ 26.49 ms │ 15.89 ms │ 1084 ms │
└─────────┴───────┴───────┴───────┴───────┴──────────┴──────────┴─────────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬───────────┬─────────┬─────────┐
│ Stat │ 1% │ 2.5% │ 50% │ 97.5% │ Avg │ Stdev │ Min │
├───────────┼─────────┼─────────┼─────────┼─────────┼───────────┼─────────┼─────────┤
│ Req/Sec │ 38,783 │ 38,783 │ 48,831 │ 57,791 │ 49,256.54 │ 3,864.7 │ 38,755 │
├───────────┼─────────┼─────────┼─────────┼─────────┼───────────┼─────────┼─────────┤
│ Bytes/Sec │ 9.18 MB │ 9.18 MB │ 11.6 MB │ 13.7 MB │ 11.7 MB │ 917 kB │ 9.18 MB │
└───────────┴─────────┴─────────┴─────────┴─────────┴───────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.

# of samples: 30

1480k requests in 30.06s, 350 MB read

FDs: 1139
Connections: 2001

docker stats
faa9e55072d2 nginx 129.04% 517.4MiB / 1GiB 50.53% 133MB / 205MB 0B / 12.3kB 7

## 10k load test

➜ phase-1 git:(main) ✗ autocannon -c 10000 -d 30 http://localhost:8080/
Running 30s test @ http://localhost:8080/
10000 connections

running [====== ] 30%(node:34284) TimeoutNegativeWarning: -1 is a negative number.
Timeout duration was set to 1.
(Use `node --trace-warnings ...` to show where the warning was created)

┌─────────┬───────┬────────┬─────────┬─────────┬───────────┬──────────┬─────────┐
│ Stat │ 2.5% │ 50% │ 97.5% │ 99% │ Avg │ Stdev │ Max │
├─────────┼───────┼────────┼─────────┼─────────┼───────────┼──────────┼─────────┤
│ Latency │ 77 ms │ 110 ms │ 1004 ms │ 1436 ms │ 240.98 ms │ 319.5 ms │ 9903 ms │
└─────────┴───────┴────────┴─────────┴─────────┴───────────┴──────────┴─────────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬────────┬───────────┬─────────┐
│ Stat │ 1% │ 2.5% │ 50% │ 97.5% │ Avg │ Stdev │ Min │
├───────────┼─────────┼─────────┼─────────┼─────────┼────────┼───────────┼─────────┤
│ Req/Sec │ 12,895 │ 12,895 │ 43,359 │ 53,215 │ 40,928 │ 10,247.52 │ 12,890 │
├───────────┼─────────┼─────────┼─────────┼─────────┼────────┼───────────┼─────────┤
│ Bytes/Sec │ 3.06 MB │ 3.06 MB │ 10.3 MB │ 12.6 MB │ 9.7 MB │ 2.43 MB │ 3.05 MB │
└───────────┴─────────┴─────────┴─────────┴─────────┴────────┴───────────┴─────────┘

Req/Bytes counts sampled once per second.

# of samples: 30

1238k requests in 30.33s, 291 MB read
158 errors (158 timeouts)

FDs: 10151
Connections: 20001

docker stats
faa9e55072d2 nginx 117.08% 585.8MiB / 1GiB 57.21% 519MB / 839MB 0B / 12.3kB 7

## 100k load test

➜ phase-1 git:(main) ✗ autocannon -c 100000 -d 30 http://localhost:8080/
Running 30s test @ http://localhost:8080/
100000 connections

running [= ] 3%

(node:36096) TimeoutNegativeWarning: -211262 is a negative number.
Timeout duration was set to 1.
(Use `node --trace-warnings ...` to show where the warning was created)
running [== ] 10%
┌─────────┬──────┬──────┬───────┬──────┬──────┬───────┬──────┐
│ Stat │ 2.5% │ 50% │ 97.5% │ 99% │ Avg │ Stdev │ Max │
├─────────┼──────┼──────┼───────┼──────┼──────┼───────┼──────┤
│ Latency │ 0 ms │ 0 ms │ 0 ms │ 0 ms │ 0 ms │ 0 ms │ 0 ms │
└─────────┴──────┴──────┴───────┴──────┴──────┴───────┴──────┘
┌───────────┬─────┬──────┬─────┬───────┬─────┬───────┬─────┐
│ Stat │ 1% │ 2.5% │ 50% │ 97.5% │ Avg │ Stdev │ Min │
├───────────┼─────┼──────┼─────┼───────┼─────┼───────┼─────┤
│ Req/Sec │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │
├───────────┼─────┼──────┼─────┼───────┼─────┼───────┼─────┤
│ Bytes/Sec │ 0 B │ 0 B │ 0 B │ 0 B │ 0 B │ 0 B │ 0 B │
└───────────┴─────┴──────┴─────┴───────┴─────┴───────┴─────┘

Req/Bytes counts sampled once per second.

# of samples: 3

338k requests in 234.39s, 0 B read
238k errors (78k timeouts)

FDs: 16486
Connections: 32699

docker stats
faa9e55072d2 nginx 1.70% 602.1MiB / 1GiB 58.80% 565MB / 911MB 0B / 12.3kB 7

## 🧠 Analysis: Why 100k Stalled (Run 1)

1. **Host Floor:** macOS Ephemeral Ports (`49152-65535`) provide 16,384 ports. Since `autocannon` was on `localhost`, every connection used 2 ports. `32699 / 2 ≈ 16350`. This perfectly matches the port range limit.
2. **Client Ceiling:** Node.js (Autocannon) saturation. 50k connections per client caused `TimeoutNegativeWarning`. The event loop was too busy to read HTTP data, leading to **0 RPS**.

**Correction Strategy:** Move to a 4-client horizontal setup (25k each) on an internal Docker network!

### 100k run - 4 clients

docker stats

CONTAINER ID NAME CPU % MEM USAGE / LIMIT MEM % NET I/O BLOCK I/O PIDS
d7c1a50f3baa nginx 100.15% 723.4MiB / 768MiB 94.19% 20.7MB / 24.3MB 10.6MB / 123MB 11
813933f53c27 04-connection-explosion-client-2-1 99.35% 443.3MiB / 768MiB 57.72% 5.98MB / 5.1MB 0B / 0B 11
244a8a1c961c 04-connection-explosion-client-1-1 100.10% 442.2MiB / 768MiB 57.58% 6.09MB / 5.17MB 0B / 0B 11
e88359eabf3a 04-connection-explosion-client-4-1 99.01% 445.8MiB / 768MiB 58.05% 6.07MB / 5.22MB 0B / 0B 11
1b491529eb0c 04-connection-explosion-client-3-1 99.53% 444.2MiB / 768MiB 57.84% 6.21MB / 5.25MB 0B / 0B 11

Peak FDs: 97066
Peak Connections: 94637

#### Client 1

➜ 04-connection-explosion git:(main) ✗ docker logs -f 04-connection-explosion-client-1-1
Running 30s test @ http://nginx:8080/
25000 connections

(node:1) TimeoutNegativeWarning: -23581 is a negative number.
Timeout duration was set to 1.
(Use `node --trace-warnings ...` to show where the warning was created)

┌─────────┬─────────┬─────────┬──────────┬──────────┬─────────────┬─────────────┬──────────┐
│ Stat │ 2.5% │ 50% │ 97.5% │ 99% │ Avg │ Stdev │ Max │
├─────────┼─────────┼─────────┼──────────┼──────────┼─────────────┼─────────────┼──────────┤
│ Latency │ 1233 ms │ 1392 ms │ 34306 ms │ 34330 ms │ 17479.03 ms │ 16146.66 ms │ 34337 ms │
└─────────┴─────────┴─────────┴──────────┴──────────┴─────────────┴─────────────┴──────────┘
┌───────────┬─────┬──────┬─────┬─────────┬─────────┬─────────┬─────────┐
│ Stat │ 1% │ 2.5% │ 50% │ 97.5% │ Avg │ Stdev │ Min │
├───────────┼─────┼──────┼─────┼─────────┼─────────┼─────────┼─────────┤
│ Req/Sec │ 0 │ 0 │ 0 │ 26,047 │ 13,020 │ 13,020 │ 26,034 │
├───────────┼─────┼──────┼─────┼─────────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 0 B │ 0 B │ 0 B │ 6.17 MB │ 3.09 MB │ 3.09 MB │ 6.17 MB │
└───────────┴─────┴──────┴─────┴─────────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.

# of samples: 2

63k requests in 37.14s, 6.17 MB read
12k errors (12k timeouts)
➜ 04-connection-explosion git:(main) ✗

#### Client 2

➜ 04-connection-explosion git:(main) ✗ docker logs -f 04-connection-explosion-client-2-1
Running 30s test @ http://nginx:8080/
25000 connections

(node:1) TimeoutNegativeWarning: -24621 is a negative number.
Timeout duration was set to 1.
(Use `node --trace-warnings ...` to show where the warning was created)

┌─────────┬────────┬─────────┬──────────┬──────────┬─────────────┬─────────────┬──────────┐
│ Stat │ 2.5% │ 50% │ 97.5% │ 99% │ Avg │ Stdev │ Max │
├─────────┼────────┼─────────┼──────────┼──────────┼─────────────┼─────────────┼──────────┤
│ Latency │ 687 ms │ 1374 ms │ 35701 ms │ 35710 ms │ 17939.39 ms │ 16979.85 ms │ 35730 ms │
└─────────┴────────┴─────────┴──────────┴──────────┴─────────────┴─────────────┴──────────┘
┌───────────┬─────┬──────┬─────┬────────┬─────────┬─────────┬────────┐
│ Stat │ 1% │ 2.5% │ 50% │ 97.5% │ Avg │ Stdev │ Min │
├───────────┼─────┼──────┼─────┼────────┼─────────┼─────────┼────────┤
│ Req/Sec │ 0 │ 0 │ 0 │ 25,759 │ 12,876 │ 12,876 │ 25,744 │
├───────────┼─────┼──────┼─────┼────────┼─────────┼─────────┼────────┤
│ Bytes/Sec │ 0 B │ 0 B │ 0 B │ 6.1 MB │ 3.05 MB │ 3.05 MB │ 6.1 MB │
└───────────┴─────┴──────┴─────┴────────┴─────────┴─────────┴────────┘

Req/Bytes counts sampled once per second.

# of samples: 2

63k requests in 37.87s, 6.1 MB read
12k errors (12k timeouts)
➜ 04-connection-explosion git:(main) ✗

#### Client 3

➜ 04-connection-explosion git:(main) ✗ docker logs -f 04-connection-explosion-client-3-1
Running 30s test @ http://nginx:8080/
25000 connections

(node:1) TimeoutNegativeWarning: -22761 is a negative number.
Timeout duration was set to 1.
(Use `node --trace-warnings ...` to show where the warning was created)

┌─────────┬────────┬─────────┬──────────┬──────────┬─────────────┬─────────────┬──────────┐
│ Stat │ 2.5% │ 50% │ 97.5% │ 99% │ Avg │ Stdev │ Max │
├─────────┼────────┼─────────┼──────────┼──────────┼─────────────┼─────────────┼──────────┤
│ Latency │ 809 ms │ 1185 ms │ 33524 ms │ 33562 ms │ 16907.92 ms │ 15835.83 ms │ 33576 ms │
└─────────┴────────┴─────────┴──────────┴──────────┴─────────────┴─────────────┴──────────┘
┌───────────┬─────┬──────┬─────┬─────────┬─────────┬─────────┬─────────┐
│ Stat │ 1% │ 2.5% │ 50% │ 97.5% │ Avg │ Stdev │ Min │
├───────────┼─────┼──────┼─────┼─────────┼─────────┼─────────┼─────────┤
│ Req/Sec │ 0 │ 0 │ 0 │ 27,103 │ 13,548 │ 13,548 │ 27,088 │
├───────────┼─────┼──────┼─────┼─────────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 0 B │ 0 B │ 0 B │ 6.42 MB │ 3.21 MB │ 3.21 MB │ 6.42 MB │
└───────────┴─────┴──────┴─────┴─────────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.

# of samples: 2

64k requests in 36.19s, 6.42 MB read
11k errors (11k timeouts)
➜ 04-connection-explosion git:(main) ✗

#### Client 4

➜ 04-connection-explosion git:(main) ✗ docker logs -f 04-connection-explosion-client-4-1
Running 30s test @ http://nginx:8080/
25000 connections

(node:1) TimeoutNegativeWarning: -19077 is a negative number.
Timeout duration was set to 1.
(Use `node --trace-warnings ...` to show where the warning was created)

┌─────────┬────────┬────────┬──────────┬──────────┬────────────┬─────────────┬──────────┐
│ Stat │ 2.5% │ 50% │ 97.5% │ 99% │ Avg │ Stdev │ Max │
├─────────┼────────┼────────┼──────────┼──────────┼────────────┼─────────────┼──────────┤
│ Latency │ 285 ms │ 922 ms │ 29627 ms │ 29721 ms │ 7529.37 ms │ 10622.08 ms │ 29759 ms │
└─────────┴────────┴────────┴──────────┴──────────┴────────────┴─────────────┴──────────┘
┌───────────┬─────┬──────┬─────────┬─────────┬───────────┬───────────┬─────────┐
│ Stat │ 1% │ 2.5% │ 50% │ 97.5% │ Avg │ Stdev │ Min │
├───────────┼─────┼──────┼─────────┼─────────┼───────────┼───────────┼─────────┤
│ Req/Sec │ 0 │ 0 │ 25,215 │ 49,151 │ 24,781.34 │ 20,061.96 │ 25,202 │
├───────────┼─────┼──────┼─────────┼─────────┼───────────┼───────────┼─────────┤
│ Bytes/Sec │ 0 B │ 0 B │ 5.98 MB │ 11.6 MB │ 5.87 MB │ 4.75 MB │ 5.97 MB │
└───────────┴─────┴──────┴─────────┴─────────┴───────────┴───────────┴─────────┘

Req/Bytes counts sampled once per second.

# of samples: 3

112k requests in 45.37s, 17.6 MB read
12k errors (12k timeouts)
➜ 04-connection-explosion git:(main) ✗
