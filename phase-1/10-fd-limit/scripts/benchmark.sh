#!/bin/bash

# Target URL (Mapped via localhost for the host machine)
TARGET_URL=${1:-"http://localhost:8080/"}
STATUS_URL="http://localhost:8080/nginx_status"
LOG_DIR="measurements"

# Benchmark Configuration
# We send 200 concurrent connections. 
# Since the FD limit is set to 128, NGINX will run out of FDs 
# (each connection uses at least 2 FDs: one for client, one for upstream).
DURATION=30
CONCURRENCY=200

mkdir -p $LOG_DIR

# Clear previous logs
> $LOG_DIR/nginx_status.log
> $LOG_DIR/docker_stats.log
> $LOG_DIR/autocannon_results.log
> $LOG_DIR/nginx_errors.log
> $LOG_DIR/nginx_fd_usage.log

echo "------------------------------------------------------------"
echo "Experiment 10: File Descriptor Limit"
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

# Poll Nginx FD usage every second
# We take all FDs across all nginx processes.
(
  while true; do
    echo "--- $(date +%H:%M:%S) ---" >> $LOG_DIR/nginx_fd_usage.log
    docker exec nginx sh -c 'ls -1 /proc/*/fd 2>/dev/null | wc -l' >> $LOG_DIR/nginx_fd_usage.log
    sleep 1
  done
) &
NGINX_FD_MONITOR_PID=$!

# Stream Docker stats (continuous output)
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" > $LOG_DIR/docker_stats.log &
DOCKER_STATS_PID=$!

# Function to cleanup background processes on exit
cleanup() {
  echo ""
  echo "Stopping monitoring processes (PIDs: $NGINX_MONITOR_PID, $NGINX_LOGS_PID, $NGINX_FD_MONITOR_PID, $DOCKER_STATS_PID)..."
  kill $NGINX_MONITOR_PID
  kill $NGINX_LOGS_PID
  kill $NGINX_FD_MONITOR_PID
  kill $DOCKER_STATS_PID
  echo "Done. All logs are saved in the '$LOG_DIR' directory."
}
trap cleanup EXIT

# --- Benchmark Phases ---

echo "Step 1: EXHAUSTING FDs ($CONCURRENCY Connections)"
# NGINX will hit the 128 limit quickly.
npx autocannon -c $CONCURRENCY -d $DURATION --no-progress "${TARGET_URL}" 2>&1 | tee -a $LOG_DIR/autocannon_results.log

echo "------------------------------------------------------------"
echo "Benchmark Complete."
echo "Check NGINX logs for 'Too many open files' errors:"
echo "docker logs nginx | grep 'socket() failed'"
