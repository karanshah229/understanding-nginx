# Answers

🧠 Section 1 — Core Mental Model

Q1

If NGINX uses non-blocking I/O, why can’t it just run one worker process total on a multi-core machine?

👉 What exactly breaks or becomes suboptimal?

Answer:

> A single worker can only execute one event at a time, regardless of how many connections it manages.

What breaks:

- No parallelism → only one core is utilized
- Event queue builds up → latency increases due to queueing delay
- Throughput is capped by a single thread’s processing speed

Non-blocking I/O removes waiting, but it does not introduce parallel execution.

Multiple workers are required to:

- Utilize multiple CPU cores (true parallelism)
- Reduce per-worker queue length (lower latency)
- Provide fault isolation (secondary benefit)

Q2

You have:

1 worker
100k idle keep-alive connections
Almost zero CPU usage

Now suddenly:

All 100k clients send requests at once

👉 What happens inside the worker step-by-step?
👉 Where is the bottleneck?

Answer:
All 100k sockets become readable around the same time
The kernel marks them as ready and epoll_wait returns a large batch of events
The worker enters the event loop and begins processing events sequentially
Each event (read → parse → process) takes some CPU time

Key issue:

> The bottleneck is the single-threaded event loop processing a large backlog of ready events

- epoll scales readiness detection, not execution
- Events are processed one-by-one
- The last request experiences significant queueing delay

Other issues:

1. open file descriptors limit - 1024 by default
2. how many CPUs are assigned to NGINX. If only a single CPU then event event loop non blocking architecture will not be able to process 100k+ connections in a short time.

Q3

Explain this precisely:

“epoll does not scale your application—your architecture does”

Answer:

> epoll solves efficient readiness notification, not execution scalability.

It allows you to:

- Avoid scanning all sockets (O(n))
- React only to active ones (O(ready))

But:

> If your architecture cannot process events in parallel or avoid blocking, epoll alone provides no scalability benefit.

Examples:

- Thread-per-request + blocking → still inefficient despite epoll
- Event loop + blocking → collapses completely

True scalability comes from:

- Non-blocking I/O
- Event-driven design
- Parallel execution (workers)

⚙️ Section 2 — Event Loop vs Blocking
Q4

You accidentally introduce a blocking call inside an NGINX worker (e.g., blocking disk read).

👉 What is the exact blast radius?

One request?
One connection?
One worker?
Entire server?

Explain why.

Answer:
The blast radius is one worker which means all the sockets registered by that worker in it's epoll instance.

Q5

Why is this combination fundamentally broken?

Event loop + blocking I/O

Give a concrete scenario where it collapses.

Answer:
Event loop + blocking I/O is fundamentally broken because it defeats the entire purpose of the event loop

Q6

Why is this combination mostly useless?

Thread-per-request + non-blocking I/O

What benefit are you failing to capture?

Answer:

> Thread-per-request + non-blocking I/O fails to capture the primary benefit of non-blocking systems: thread reuse during waiting

You lose:

- High concurrency per thread
- Memory efficiency
- Reduced scheduling overhead

> You pay the cost of threads without gaining the benefits of event-driven multiplexing.

🔁 Section 3 — epoll Deep Understanding
Q7

What would happen if instead of epoll, NGINX used:

```
for each socket:
read(socket)

(non-blocking)
```

👉 Why is this inefficient even though it's non-blocking?

Answer:
This becomes busy polling.

Even with non-blocking reads:

- You repeatedly check all sockets
- Most are not ready
- CPU cycles are wasted scanning inactive connections

> Complexity becomes O(n) per iteration instead of O(ready)

Q8

What problem does epoll solve that select() and poll() struggle with?

(Hint: think scale, not just functionality)

Answer:

> They require scanning all registered file descriptors on every call

Problems:

- O(n) complexity
- Memory copying overhead
- Poor scalability beyond a few thousand FDs

epoll solves this by:

- Maintaining readiness state in the kernel
- Returning only active events

> It scales with number of active events, not total connections.

Q9

Does epoll tell you:

“data is available”
OR
“you can read without blocking”

👉 Why is this distinction important?

Answer:
“you can read without blocking”
Why this matters:

- “Data is available” is ambiguous (how much? complete request?)
- epoll only guarantees that the operation will not block at that moment

Implication:

- You must still handle partial reads/writes
- You must design for incremental processing

> This is why event-driven systems are inherently state-machine based.

🧵 Section 4 — Workers & Processes
Q10

Two workers are running.

Worker A is overloaded (many active connections).
Worker B is mostly idle.

👉 Can Worker B “help” Worker A?

Why or why not?

Answer:
No, Worker B cannot help Worker A

Because:

- Connections are bound to the worker that accepted them
- Each worker has its own epoll instance and event loop
- There is no shared work queue

Work redistribution would require:

- Cross-process FD transfer
- Shared state
- Synchronization

Which would introduce:

- Locking
- Contention
- Performance degradation

> NGINX trades perfect load balancing for zero coordination overhead.

Q11

If one worker crashes:

What happens to its active connections?
What does the master process do?

Answer:

- If a worker crashes, it's blast radius is only all the conenctions it has accepted.
- The master process will immediately spin up another worker process to take over.
- All active connections in that worker are dropped.
- Clients observe errors or retries.

Q12

Why did NGINX choose processes instead of threads, even though threads are “lighter”?

Give at least 3 deep reasons.

Answer:

NGINX prefers processes over threads due to:

1. Isolation

- Memory is not shared
- No locks required
- No race conditions

2. Predictability

- No thread scheduling contention
- Stable latency under load

3. Fault containment

- Worker crash does not affect others

4. Simplicity of design

- Each worker is an independent event loop

📡 Section 5 — File Descriptors & Limits
Q13

You increase:

ulimit -n 200000

But NGINX still fails under load.

👉 What else could be limiting you?

1. The number of CPUs since we can have as many workers / exection streams as the number of CPUs

Q14

Why are idle keep-alive connections not free in NGINX?

What resources do they consume?

Answer:

- File descriptors
- Kernel socket structures
- NGINX connection state (buffers, metadata)
- Memory for connection pools

> They occupy resources and limit how many active connections you can support.

⚖️ Section 6 — Backpressure & Stability
Q15

Backend becomes slow (e.g., DB latency spikes).
👉 Trace what happens:
Client → NGINX → Backend → NGINX → Client

Where does pressure build first?

Answer:

1. First it'll build on Backend as NGINX will keep feeding it requests and Backend may start returning 5xx as pressure builds up.
2. If NGINX is configured in a particular way then it will stop accepting new connections as pressure builds up.

NGINX can apply backpressure via:

- connection limits
- buffering
- timeouts

Q16

Why doesn’t NGINX crash immediately under high load, while naive servers do?
What mechanisms conceptually prevent collapse?

Answer:

> It degrades by increasing latency, not by exhausting system resources immediately.

- Non-blocking I/O (no thread exhaustion)
- Bounded workers (no unbounded thread creation)
- Event-driven processing
- Backpressure mechanisms
- Isolation across workers

🧩 Section 7 — Architecture Thinking
Q17

Compare:

NGINX
Apache Tomcat

👉 Not features—execution model differences

Answer:

- NGINX → event-driven, non-blocking, multiplexed I/O
- Apache Tomcat → thread-per-request, blocking model

Q18

If NGINX is so efficient, why don’t we use it to run business logic like a full application server?

Answer:

- Workers are single-threaded
- CPU-heavy work blocks the event loop
- No flexible task scheduling

> It is optimized for I/O handling, not computation.

That’s why:

> NGINX → front proxy
>
> App servers (e.g., Node.js, JVM apps) → business logic

Q19 (Very Deep)

Where does memory live in NGINX for a request?

Stack?
Heap?
Shared memory?

Explain how this differs from thread-per-request servers.

Answer:

Memory in NGINX:

- Stack → function calls within worker thread
- Heap → request/connection state (primary storage)
- Shared memory → optional (caches, zones)

> All request state lives in the worker process heap and is accessed by the event loop.

Compared to thread-per-request

Thread model:

- Stack per thread (large)
- Request state often tied to thread lifecycle

NGINX:

- Shared heap within worker
- No per-request thread overhead

🔥 Final Boss Question
Q20

Design a failure scenario:

NGINX is running fine at 10k RPS, but suddenly latency spikes massively while CPU is still low.

👉 Give 3 completely different root causes, all consistent with NGINX architecture.

Answer:

Three distinct root causes:

1. Event loop blocking
    - Unexpected CPU-heavy operation
    - Blocking I/O (disk, DNS, etc.)

Worker stalls → queueing delay increases → latency spikes

2. Upstream latency increase
    - Backend slows down
    - Connections remain open longer

More active connections → larger event queues → higher latency

3. Load imbalance across workers
    - Uneven distribution of active connections
    - One worker overloaded

Some requests experience high latency despite low overall CPU

---

# Original Attempt

🧠 Section 1 — Core Mental Model

Q1

If NGINX uses non-blocking I/O, why can’t it just run one worker process total on a multi-core machine?

👉 What exactly breaks or becomes suboptimal?

Answer:
NGING can physically run a single worker. But it will not be able to take full advantage of the multi-core architecture. Essentially we'll wasting resources available to us.
Also multiple workers ensure fault tolerance. If one worker crashes, the others can continue to handle requests.

Q2

You have:

1 worker
100k idle keep-alive connections
Almost zero CPU usage

Now suddenly:

All 100k clients send requests at once

👉 What happens inside the worker step-by-step?
👉 Where is the bottleneck?

Answer:
Even if all connections send data, there will be some difference in the time it arrives to the server.
Linux will inform NGINX that a socket has received data in the order of the arrival of the connections.
The worker that registered this socket with epoll picks it up and processes it.
Limitations

1. open file descriptors limit - 1024 by default
2. how many CPUs are assigned to NGINX. If only a single CPU then event event loop non blocking architecture will not be able to process 100k+ connections in a short time.

Q3

Explain this precisely:

“epoll does not scale your application—your architecture does”

Answer:
If we had used epoll with a thread per request model then it would not scale well.
Each thread is tied to a request and is blocked till it finishes it's entire lifecycle and returns to the pool. So epoll in combination with event loop model will scale.

⚙️ Section 2 — Event Loop vs Blocking
Q4

You accidentally introduce a blocking call inside an NGINX worker (e.g., blocking disk read).

👉 What is the exact blast radius?

One request?
One connection?
One worker?
Entire server?

Explain why.

Answer:
The blast radius is one worker which means all the sockets registered by that worker in it's epoll instance.

Q5

Why is this combination fundamentally broken?

Event loop + blocking I/O

Give a concrete scenario where it collapses.

Answer:
The event loop model is run on very few threads - generally 1 per CPU.
If a blocking call is made then that thread will be blocked and will not be able to process any other requests.
Essentially turning it into a request per thread model.

Q6

Why is this combination mostly useless?

Thread-per-request + non-blocking I/O

What benefit are you failing to capture?

Answer:
Even if a thread per request model uses non blocking I/O because the lifecycle of the request has not finished, the thread cannot go back to the pool to process other requests.

?

🔁 Section 3 — epoll Deep Understanding
Q7

What would happen if instead of epoll, NGINX used:

for each socket:
read(socket)

(non-blocking)

👉 Why is this inefficient even though it's non-blocking?

Answer:
The problem here is that NGINX is constantly checking for data on sockets which are not ready.
This is wasteful in terms of CPU cycles.

Q8

What problem does epoll solve that select() and poll() struggle with?

(Hint: think scale, not just functionality)

Answer:
epoll turns a pull model of select or poll into a push model where the application can register interest and OS notifies it when it is available.
This saves crucial CPU cycles of the application which can be used to process many more thousands of requests instead of checking for data on sockets which are not ready.

Q9

Does epoll tell you:

“data is available”
OR
“you can read without blocking”

👉 Why is this distinction important?

Answer:
“you can read without blocking”
I don't understand Why is this distinction important. Explain it to me again.

🧵 Section 4 — Workers & Processes
Q10

Two workers are running.

Worker A is overloaded (many active connections).
Worker B is mostly idle.

👉 Can Worker B “help” Worker A?

Why or why not?

Answer:
The way NGINX is designed, it is not possible for Worker B to help Worker A.
Both run their event loops and epoll queues internally for specified sockets.
When the requests are incoming for the first time, the workers randomly pick up requests based on their availability and incoming request.
So it is possible that Worker A has accepted connections that may be very active and hence it will be overloaded.
But since it is overloaded, it will not be able to accept new connections and these will be accepted Worker B, thus balancing out workload eventually.

Q11

If one worker crashes:

What happens to its active connections?
What does the master process do?

Answer:
If a worker crashes, it's blast radius is only all the conenctions it has accepted.
The master process will immediately spin up another worker process to take over.
The active connections will probably see an error or retries.

Q12

Why did NGINX choose processes instead of threads, even though threads are “lighter”?

Give at least 3 deep reasons.

Answer:

- Process isolation: If a process crashes it only affects the current process
- Process are mapped directly a CPU
- Workers don't need to share any memory - event loop, epoll queue etc are all internal to the worker process.

📡 Section 5 — File Descriptors & Limits
Q13

You increase:

ulimit -n 200000

But NGINX still fails under load.

👉 What else could be limiting you?

1. The number of CPUs since we can have as many workers as the number of CPUs

Q14

Why are idle keep-alive connections not free in NGINX?

What resources do they consume?

Answer:
idle keep-alive connections are only stored as file descriptors in memory. So they shouldn't consume any significant resources.

⚖️ Section 6 — Backpressure & Stability
Q15

Backend becomes slow (e.g., DB latency spikes).
👉 Trace what happens:
Client → NGINX → Backend → NGINX → Client

Where does pressure build first?

Answer:

1. First it'll build on Backend as NGINX will keep feeding it requests and Backend may start returning 5xx as pressure builds up.
2. If NGINX is configured in a particular way then it will stop accepting new connections as pressure builds up.

Q16

Why doesn’t NGINX crash immediately under high load, while naive servers do?
What mechanisms conceptually prevent collapse?

Answer:
NGINX may become slow but for it to crash something fundamentally has to go wrong.
Workers are responsible for processing / reading from sockets.
Even if some operation is blocking which it should not be, the worker will not be able to process other requests and will eventually may die.
But other workers are not disturbed and continue to process requests.

🧩 Section 7 — Architecture Thinking
Q17

Compare:

NGINX
Apache Tomcat

👉 Not features—execution model differences

Answer:
Event loop + non blocking I/O model vs Thread-per-request blocking model

Q18

If NGINX is so efficient, why don’t we use it to run business logic like a full application server?

Answer:
The power of NGINX is event loop + non blocking I/O.
This combination can be found in Nodejs and backend applications are run on Node.

Q19 (Very Deep)

Where does memory live in NGINX for a request?

Stack?
Heap?
Shared memory?

Explain how this differs from thread-per-request servers.

Answer:
Since the job of accepting and process requests is of a worker which is a process, it has it's own stack and heap where it will store data.
The request data is stored in the heap of the worker process so that all threads - 1 request accept thread, disk I/O, etc can access that data.
thread-per-request servers will store data in stack of the thread as it is solely responsible for the entire lifecycle of the request.

🔥 Final Boss Question
Q20

Design a failure scenario:

NGINX is running fine at 10k RPS, but suddenly latency spikes massively while CPU is still low.

👉 Give 3 completely different root causes, all consistent with NGINX architecture.

Answer:

- If there is some blocking work that is triggered because of some condition then latency can spike.
  Can't think of other root causes.
