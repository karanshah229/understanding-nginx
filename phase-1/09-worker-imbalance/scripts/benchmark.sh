#!/bin/bash

# Target URL (Mapped via localhost for the host machine)
TARGET_URL=${1:-"http://localhost:8080/"}
STATUS_URL="http://localhost:8080/nginx_status"
LOG_DIR="measurements"

# Benchmark Configuration
# FINAL STRESS TEST: We use a 50MB randomized payload and Level 9 Gzip.
# This forces the NGINX worker to perform maximum pattern searching (CPU) 
# while stalling its own event loop frequently.
DURATION=120
CONCURRENCY_SLOW=1
CONCURRENCY_FAST=20

mkdir -p $LOG_DIR

# Clear previous logs
> $LOG_DIR/nginx_status.log
> $LOG_DIR/docker_stats.log
> $LOG_DIR/nginx_top.log
> $LOG_DIR/autocannon_results_slow.log
> $LOG_DIR/autocannon_results_fast.log

echo "------------------------------------------------------------"
echo "Experiment 9: Worker Imbalance (FINAL STRESS TEST)"
echo "------------------------------------------------------------"

# --- Background Monitoring ---

echo "Starting background measurements (NGINX status, Docker stats & Top)..."

# Poll Nginx status every second
(
  while true; do
    echo "--- $(date +%H:%M:%S) ---" >> $LOG_DIR/nginx_status.log
    curl -s $STATUS_URL >> $LOG_DIR/nginx_status.log
    sleep 1
  done
) &
NGINX_MONITOR_PID=$!

# Stream Docker stats (continuous output)
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" > $LOG_DIR/docker_stats.log &
DOCKER_STATS_PID=$!

# Capture per-process CPU inside NGINX to see the worker imbalance
# We use the explicit container name 'nginx' and batch mode.
docker exec nginx top -b -d 0.5 > $LOG_DIR/nginx_top.log 2>&1 &
NGINX_TOP_PID=$!

# Function to cleanup background processes on exit
cleanup() {
  echo ""
  echo "Stopping monitoring processes (PIDs: $NGINX_MONITOR_PID, $DOCKER_STATS_PID, $NGINX_TOP_PID)..."
  kill $NGINX_MONITOR_PID
  kill $DOCKER_STATS_PID
  kill $NGINX_TOP_PID
  echo "Done. All logs are saved in the '$LOG_DIR' directory."
}
trap cleanup EXIT

# --- Benchmark Phases ---

echo "Step 1: PINNING A WORKER (1 Connection @ 50MB randomized stream)"
# We start the background load. The worker will stay pinned at 100% CPU 
# searching for compression patterns in randomized data.
npx autocannon -c $CONCURRENCY_SLOW -d $DURATION --no-progress "${TARGET_URL}slow" 2>&1 | tee -a $LOG_DIR/autocannon_results_slow.log &
AUTOCANNON_SLOW_PID=$!

sleep 10

echo "Step 2: PROBING IMBALANCE (20 Connections to /fast)"
# Half of these will experience the 'Hot Worker' stutter, causing dramatic p99 spikes.
npx autocannon -c $CONCURRENCY_FAST -d 40 --no-progress "${TARGET_URL}fast" 2>&1 | tee -a $LOG_DIR/autocannon_results_fast.log

echo "⏳ Waiting for initial load to complete..."
wait $AUTOCANNON_SLOW_PID

echo "------------------------------------------------------------"
echo "Benchmark Complete."
