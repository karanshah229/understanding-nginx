# 🧪 Experiment 13 — TLS Overhead

## 🎯 Objective

Measure and quantify the computational cost (CPU) and latency penalty introduced by enabling TLS (HTTPS) on NGINX compared to a plain HTTP baseline.

## ⚙️ Setup

- **NGINX**: Configured with two server blocks:
    - Port 8080: HTTP (Baseline)
    - Port 8443: HTTPS (TLSv1.2/v1.3, Optimized Ciphers)
- **Backend**: Spring Boot (Java) returning a simple string.
- **Load Tool**: `autocannon` (100 concurrent connections, 1000 RPS rate limit).
- **Self-Signed Certs**: 2048-bit RSA.

## 💡 Hypothesis

Enabling TLS will increase NGINX CPU utilization due to the cryptographic handshake and symmetric encryption. We also expect a slight increase in tail latency (p99) due to additional round-trips required for the TLS handshake during connection establishment.

## 📏 Measure

- **CPU Usage**: Captured via `docker stats` for the `nginx` container.
- **Latency (p50, p95, p99)**: Measured by `autocannon`.
- **RPS (Requests Per Second)**: To ensure consistent load during both tests.

## 👀 Observe

- **CPU Burst**: The initial handshake for 100 concurrent connections caused a **3x CPU spike** (35.7% vs 12.6%) compared to HTTP.
- **Sustained Load**: Ongoing encryption added a **~30-40% relative increase** in baseline CPU utilization.
- **Tail Latency**: The **p99 latency** increased by **~15%** (from 171ms to 197ms), reflecting the cryptographic "tax" on connection establishment.
- **Avg Latency**: Remained stable (and even slightly improved) due to NGINX's efficient session caching once the initial overhead was paid.

## 🎓 Learn

- **Handshake vs. Payload**: TLS overhead is front-loaded. Asymmetric cryptography (RSA/ECDSA) during the handshake is 10-100x more expensive than symmetric encryption (AES) during data transfer.
- **Capacity Planning**: An architect must size the system based on **connection churn**, not just throughput. A "Connection Storm" (many new HTTPS clients) can saturate the CPU even if the bandwidth usage is low.
- **Hardware Acceleration**: Modern CPUs (AES-NI) make symmetric encryption almost "free," but the handshake remains a tangible compute bottleneck. 
- **The "Keep-Alive" Strategy**: Sustaining long-lived connections is the most effective way to eliminate TLS overhead in high-traffic systems.
