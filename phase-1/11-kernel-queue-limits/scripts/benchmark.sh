#!/bin/bash

# Target URL (Mapped via localhost for the host machine)
TARGET_URL=${1:-"http://localhost:8080/"}
STATUS_URL="http://localhost:8080/nginx_status"
LOG_DIR="measurements"

# Benchmark Configuration
# We send a burst of 100 concurrent connections. 
# Since the kernel backlog (somaxconn) is 5, many will be dropped.
DURATION=30
CONCURRENCY=100

mkdir -p $LOG_DIR

# Clear previous logs
> $LOG_DIR/nginx_status.log
> $LOG_DIR/docker_stats.log
> $LOG_DIR/autocannon_results.log
> $LOG_DIR/nginx_errors.log
> $LOG_DIR/kernel_drops.log

echo "------------------------------------------------------------"
echo "Experiment 11: Kernel Queue Limits"
echo "------------------------------------------------------------"

# --- Background Monitoring ---

echo "Starting background measurements (NGINX status & Docker stats)..."

# Poll Nginx status every second
(
  while true; do
    echo "--- $(date +%H:%M:%S) ---" >> $LOG_DIR/nginx_status.log
    curl -s $STATUS_URL >> $LOG_DIR/nginx_status.log
    sleep 1
  done
) &
NGINX_MONITOR_PID=$!

# Monitor NGINX Error Logs
docker logs -f nginx > $LOG_DIR/nginx_errors.log 2>&1 &
NGINX_LOGS_PID=$!

# Stream Docker stats (continuous output)
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" > $LOG_DIR/docker_stats.log &
DOCKER_STATS_PID=$!

# Poll Kernel Listen Drops every second
# This shows exactly WHEN the drops happen (e.g. only during the initial burst)
(
  while true; do
    echo "--- $(date +%H:%M:%S) ---" >> $LOG_DIR/kernel_drops.log
    docker exec nginx netstat -s | grep -E "SYNs to LISTEN sockets dropped|times the listen queue of a socket overflowed" >> $LOG_DIR/kernel_drops.log
    sleep 1
  done
) &
KERNEL_MONITOR_PID=$!

# Function to cleanup background processes on exit
cleanup() {
  echo ""
  echo "Stopping monitoring processes (PIDs: $NGINX_MONITOR_PID, $NGINX_LOGS_PID, $DOCKER_STATS_PID, $KERNEL_MONITOR_PID)..."
  kill $NGINX_MONITOR_PID
  kill $NGINX_LOGS_PID
  kill $DOCKER_STATS_PID
  kill $KERNEL_MONITOR_PID
  echo "Done. All logs are saved in the '$LOG_DIR' directory."
}
trap cleanup EXIT

# --- Benchmark Phases ---

echo "Step 0: Capturing Kernel Stats (BEFORE)"
docker exec nginx cat /proc/net/netstat > $LOG_DIR/netstat_before.log

echo "Step 1: BURSTING THROUGH THE QUEUE ($CONCURRENCY Connections)"
# The kernel will drop connections because the backlog of 5 is exceeded immediately.
npx autocannon -c $CONCURRENCY -d $DURATION --no-progress "${TARGET_URL}" 2>&1 | tee -a $LOG_DIR/autocannon_results.log

echo "Step 2: Capturing Kernel Stats (AFTER)"
docker exec nginx cat /proc/net/netstat > $LOG_DIR/netstat_after.log

echo "------------------------------------------------------------"
echo "Benchmark Complete."
echo "Check NGINX results for connection errors and latency spikes."
echo "Check $LOG_DIR/netstat_after.log for kernel-level ListenDrops."
