# nginx

# 🧠 Phase 0 — Mental Model First (Before Touching Code)

You need to internalize this:

> NGINX is an event-driven, non-blocking, single-threaded-per-worker load-shaping system built around epoll/kqueue.

Contrast that with:

Thread-per-request (like Apache HTTP Server older models)
Thread pool models (like Apache Tomcat)

👉 Key concepts to study before coding:

- Event loop vs thread-per-request
- Non-blocking I/O
- epoll (Linux)
- File descriptors
- Backpressure

# 🔬 Phase 1 — Black Box Experiments (Observe Behavior)

Goal: Build intuition without reading internals

1. Baseline Server
   Spin up NGINX with:
   Static file serving
   Simple reverse proxy
2. Load Testing

Use:

autocannon
wrk

Run experiments:

Experiment A — Static files
Serve a large file (100MB)
Measure:
Throughput
Latency
CPU

👉 Insight:

Why is NGINX so efficient here? (sendfile, zero-copy)
Experiment B — Reverse proxy to slow backend
Backend: Node server with artificial delay (100ms)

Observe:

How many concurrent requests before collapse?
Memory usage vs concurrency

👉 Insight:

NGINX doesn’t “block” per request
Experiment C — Connection explosion
10k–100k concurrent connections

Monitor:

top, htop
lsof | wc -l

👉 Insight:

Few threads handling massive concurrency

# ⚙️ Phase 2 — Gray Box (Configuration as a Programming Model)

Now treat NGINX config as a DSL.

1. Worker Model Experiments

Change:

worker_processes 1;
worker_connections 1024;

Then:

worker_processes auto;

👉 Measure:

CPU core utilization
Throughput scaling 2. Keepalive & Connection Reuse

Test:

keepalive_timeout 0;
keepalive_timeout 65;

👉 Measure:

Latency
Connection churn 3. Buffering Behavior

Disable buffering:

proxy_buffering off;

👉 Compare:

Memory usage
Latency under load 4. Rate Limiting

Implement:

limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;

👉 Test burst traffic

# 🧬 Phase 3 — White Box (Rebuild Core Concepts Yourself)

Now you reimplement parts of NGINX.

Project 1 — Build a Mini Event Loop Server (Node.js)

Use:

Node.js

Write:

TCP server
Handle 10k connections
Non-blocking I/O

👉 Then simulate:

Blocking vs non-blocking
Project 2 — Build a Reverse Proxy

Features:

Accept request
Forward to backend
Return response

Add:

Connection pooling
Timeout handling

👉 Now you’ll feel why NGINX exists

Project 3 — Simulate Thread-per-Request Server

Use:

Python or Java

Create:

One thread per request

Compare with your event loop server

👉 This is where the difference clicks

# ⚡ Phase 4 — Systems Thinking (What Makes NGINX Special)

Now revisit NGINX features with experiments:

1. Zero-Copy (sendfile)

Test:

With and without sendfile on;

👉 Observe CPU drop

2. Caching Layer

Enable:

proxy_cache_path /tmp/cache keys_zone=mycache:10m;

Test:

Cache hit vs miss latency 3. Load Balancing

Implement:

upstream backend {
least_conn;
}

Compare:

round robin
least_conn 4. TLS Termination

Enable HTTPS

Measure:

CPU overhead
Latency impact

# 🆚 Phase 5 — Compare Architectures (Critical for Principal Level)

Now compare with:

🔹 NGINX vs HAProxy
Both event-driven
HAProxy is more specialized for L4/L7 load balancing

👉 Experiment:

Same backend
Same load
Compare latency + throughput
🔹 NGINX vs Apache HTTP Server
Thread vs event-driven

👉 Experiment:

High concurrency (10k connections)
🔹 NGINX vs Apache Tomcat
Application server vs reverse proxy

👉 Experiment:

Put NGINX in front of Tomcat

# 📊 Phase 6 — Observability (Think Like a Systems Engineer)

Track:
CPU per worker
Context switches
Open file descriptors
Network throughput

Tools:

htop
strace
perf
netstat
Advanced Experiment

Run:

strace -p <nginx_worker_pid>

👉 Watch:

epoll_wait
read/write syscalls

This is where real understanding happens

# 🧩 Phase 7 — Read the Source (Only Now)

Now go to:

NGINX source code

Focus on:

Event loop implementation
Worker lifecycle
Request processing pipeline

👉 Don’t try to read everything—trace a single request.

🧠 Final Mental Model You Should Reach

By the end, you should be able to answer:

Why does NGINX scale to 100k connections?
Why are threads avoided?
Where does memory go per connection?
How does backpressure work?
When does NGINX become the bottleneck?
🚀 Bonus (Very High Signal for You)

Given your backend + infra inclination:

Build this mini project:

👉 “NGINX Performance Lab”

Dockerized setup
Switch between:
NGINX
HAProxy
Node proxy
Run automated benchmarks
Output:
Throughput
Latency
CPU
Memory
If You Want Next Step

I can design:

A day-by-day 2–3 week deep dive plan
Or a project-based lab repo structure (with experiments + scripts)

That would take this from learning → mastery.
