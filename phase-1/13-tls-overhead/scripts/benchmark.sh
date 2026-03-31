#!/bin/bash

# Target URLs
HTTP_URL="http://localhost:8080/"
HTTPS_URL="https://localhost:8443/"
STATUS_URL="http://localhost:8080/nginx_status"
LOG_DIR="measurements"

# Benchmark Configuration
DURATION=30
CONCURRENCY=100
RATE=1000

mkdir -p $LOG_DIR

# Clear previous logs
> $LOG_DIR/nginx_status.log
> $LOG_DIR/docker_stats.log
> $LOG_DIR/autocannon_results.log

echo "------------------------------------------------------------"
echo "Experiment 13: TLS Overhead"
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

# Stream Docker stats (continuous output)
docker stats nginx --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" > $LOG_DIR/docker_stats.log &
DOCKER_STATS_PID=$!

# Function to cleanup background processes on exit
cleanup() {
  echo ""
  echo "Stopping monitoring processes..."
  kill $NGINX_MONITOR_PID
  kill $DOCKER_STATS_PID
  echo "Done. All logs are saved in the '$LOG_DIR' directory."
}
trap cleanup EXIT

# --- Benchmark Phases ---

echo "Step 1: RUNNING HTTP BASELINE (Port 8080)"
npx autocannon -c $CONCURRENCY -d $DURATION -R $RATE --no-progress "${HTTP_URL}" 2>&1 | tee -a $LOG_DIR/autocannon_results.log

echo ""
echo "Waiting for system to stabilize..."
sleep 5

echo "Step 2: RUNNING HTTPS STRESS TEST (Port 8443)"
# Use NODE_TLS_REJECT_UNAUTHORIZED=0 for self-signed certs (host-based)
NODE_TLS_REJECT_UNAUTHORIZED=0 npx autocannon -c $CONCURRENCY -d $DURATION -R $RATE --no-progress "${HTTPS_URL}" 2>&1 | tee -a $LOG_DIR/autocannon_results.log

echo "------------------------------------------------------------"
echo "Benchmark Complete."
echo "Compare logs in $LOG_DIR/autocannon_results.log for deltas."
echo "------------------------------------------------------------"
