#!/bin/bash

# Target URL (Mapped via localhost for the host machine)
TARGET_URL=${1:-"http://localhost:8080/"}
STATUS_URL="http://localhost:8080/nginx_status"
LOG_DIR="measurements"

mkdir -p $LOG_DIR

# Clear previous logs
> $LOG_DIR/nginx_status.log
> $LOG_DIR/docker_stats.log
> $LOG_DIR/fd_usage.log

echo "------------------------------------------------------------"
echo "Experiment 12: Keep-Alive Cost"
echo "------------------------------------------------------------"

# Wait for NGINX container to be ready
echo "Waiting for NGINX container to initialize..."
until [ "$(docker inspect -f '{{.State.Status}}' nginx 2>/dev/null)" == "running" ]; do
    sleep 1
done

# --- Background Monitoring ---

echo "Starting background measurements (NGINX status, Docker stats, and Worker FDs)..."

# Poll Nginx status every second
(
  while true; do
    echo "--- $(date +%H:%M:%S) ---" >> $LOG_DIR/nginx_status.log
    curl -s $STATUS_URL >> $LOG_DIR/nginx_status.log
    sleep 1
  done
) &
NGINX_MONITOR_PID=$!

# Record Docker stats in a loop (more robust than streaming)
(
  while true; do
    echo "--- $(date +%H:%M:%S) ---" >> $LOG_DIR/docker_stats.log
    docker stats nginx --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}" >> $LOG_DIR/docker_stats.log
    sleep 1
  done
) &
DOCKER_STATS_PID=$!

# Monitor ALL NGINX Worker FDs every second
(
  while true; do
    echo "--- $(date +%H:%M:%S) ---" >> $LOG_DIR/fd_usage.log
    # List all nginx worker process IDs
    WORKER_PIDS=$(docker exec nginx pgrep -f "nginx: worker process")
    
    TOTAL_FD=0
    for PID in $WORKER_PIDS; do
        # Count open file descriptors (sockets) for this worker
        FD_COUNT=$(docker exec nginx ls /proc/$PID/fd | wc -l)
        TOTAL_FD=$((TOTAL_FD + FD_COUNT))
    done
    
    echo "Total FDs across $(echo $WORKER_PIDS | wc -w) Workers: $TOTAL_FD" >> $LOG_DIR/fd_usage.log
    sleep 1
  done
) &
FD_MONITOR_PID=$!

# Function to cleanup background processes on exit
cleanup() {
  echo ""
  echo "Stopping monitoring processes..."
  kill $NGINX_MONITOR_PID
  kill $DOCKER_STATS_PID
  kill $FD_MONITOR_PID
  echo "Done. All logs are saved in the '$LOG_DIR' directory."
}
trap cleanup EXIT

# --- Benchmark Dashboard ---

echo "Monitoring... (Press Ctrl+C to stop when load concludes)"
echo ""
echo "Note: The load-generator containers are already running."
echo "I am now tracking $(docker exec nginx pgrep -f 'nginx: worker process' | wc -w) Workers."
echo ""

while true; do
    # Display live stats to console
    WORKER_PIDS=$(docker exec nginx pgrep -f "nginx: worker process" 2>/dev/null)
    TOTAL_FD=0
    for PID in $WORKER_PIDS; do
        FD_COUNT=$(docker exec nginx ls /proc/$PID/fd 2>/dev/null | wc -l)
        TOTAL_FD=$((TOTAL_FD + FD_COUNT))
    done
    
    WAITING=$(curl -s $STATUS_URL 2>/dev/null | grep "Waiting" | awk '{print $6}')
    MEM=$(docker stats nginx --no-stream --format "{{.MemUsage}}" 2>/dev/null)
    
    echo -ne "\r[LIVE] Waiting Conns: ${WAITING:-0} | Total Worker FDs: $TOTAL_FD | NGINX RAM: ${MEM:-N/A}   "
    sleep 1
done
