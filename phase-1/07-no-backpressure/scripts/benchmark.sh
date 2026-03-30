#!/bin/bash

# Target URL (Mapped via localhost for the host machine)
TARGET_URL=${1:-"http://localhost:8080/"}
STATUS_URL="http://localhost:8080/nginx_status"
LOG_DIR="measurements"

# Benchmark Configuration
# Note: Different experiments will override these per step
DURATION=60
CONCURRENCY=2000

mkdir -p $LOG_DIR

# Clear previous logs
> $LOG_DIR/nginx_status.log
> $LOG_DIR/docker_stats.log
> $LOG_DIR/autocannon_results.log

echo "------------------------------------------------------------"
echo "Experiment 7: Remove Backpressure Controls"
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
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" > $LOG_DIR/docker_stats.log &
DOCKER_STATS_PID=$!

# Function to cleanup background processes on exit
cleanup() {
  echo ""
  echo "Stopping monitoring processes (PIDs: $NGINX_MONITOR_PID, $DOCKER_STATS_PID)..."
  kill $NGINX_MONITOR_PID
  kill $DOCKER_STATS_PID
  echo "Done. All logs are saved in the '$LOG_DIR' directory."
}
trap cleanup EXIT

# --- Benchmark Phases ---

echo "Step 1: BREAKING POINT (High Concurrency, $CONCURRENCY connections)"
# Redirecting stderr to stdout (2>&1) and disabling progress bar for clean logs
npx autocannon -c $CONCURRENCY -d $DURATION --no-progress $TARGET_URL 2>&1 | tee -a $LOG_DIR/autocannon_results.log

echo "------------------------------------------------------------"
echo "Benchmark Complete."
