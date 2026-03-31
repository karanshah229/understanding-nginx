#!/bin/bash

# Configuration
LOG_DIR="measurements"
STATUS_URL="http://localhost:80/status"
BACKEND_METRICS_URL="http://localhost:8081/management/threads"

# Ports for the three scenarios
PORT_KERNEL=8001
PORT_NGINX=8002
PORT_BACKEND=8003

DEFAULT_DURATION=20
DEFAULT_CONCURRENCY=100

mkdir -p $LOG_DIR

# Clear previous logs
> $LOG_DIR/nginx_status.log
> $LOG_DIR/docker_stats.log
> $LOG_DIR/kernel_drops.log
> $LOG_DIR/backend_threads.log
> $LOG_DIR/autocannon_results.log

echo "------------------------------------------------------------"
echo "Experiment 14: Where Does the Queue Live? (Synthesis)"
echo "------------------------------------------------------------"

# --- Background Monitoring ---

echo "Starting background measurements..."

# Poll metrics every second
(
  while true; do
    TIMESTAMP=$(date +%H:%M:%S)
    
    # 1. NGINX Status
    echo "--- $TIMESTAMP ---" >> $LOG_DIR/nginx_status.log
    curl -s $STATUS_URL >> $LOG_DIR/nginx_status.log
    
    # 2. Kernel Drops (TcpExtListenOverflows)
    echo "--- $TIMESTAMP ---" >> $LOG_DIR/kernel_drops.log
    docker exec nginx nstat -az TcpExtListenOverflows >> $LOG_DIR/kernel_drops.log
    
    # 3. Backend Threads
    echo "--- $TIMESTAMP ---" >> $LOG_DIR/backend_threads.log
    curl -s $BACKEND_METRICS_URL >> $LOG_DIR/backend_threads.log
    
    sleep 1
  done
) &
MONITOR_PID=$!

# Stream Docker stats
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" > $LOG_DIR/docker_stats.log &
DOCKER_STATS_PID=$!

# Cleanup function
cleanup() {
  echo ""
  echo "Stopping monitoring processes (PIDs: $MONITOR_PID, $DOCKER_STATS_PID)..."
  kill $MONITOR_PID
  kill $DOCKER_STATS_PID
  echo "Done. All logs are saved in the '$LOG_DIR' directory."
}
trap cleanup EXIT

# --- Benchmark Phases ---

echo "Scenario A: KERNEL QUEUE (Port $PORT_KERNEL)"
echo "------------------------------------------------------------"
npx autocannon -c $DEFAULT_CONCURRENCY -d $DEFAULT_DURATION --no-progress "http://localhost:$PORT_KERNEL" 2>&1 | tee -a $LOG_DIR/autocannon_results.log

echo -e "\nScenario B: NGINX QUEUE (Port $PORT_NGINX)"
echo "------------------------------------------------------------"
npx autocannon -c $DEFAULT_CONCURRENCY -d $DEFAULT_DURATION --no-progress "http://localhost:$PORT_NGINX" 2>&1 | tee -a $LOG_DIR/autocannon_results.log

echo -e "\nScenario C: BACKEND QUEUE (Port $PORT_BACKEND)"
echo "------------------------------------------------------------"
npx autocannon -c $DEFAULT_CONCURRENCY -d $DEFAULT_DURATION --no-progress "http://localhost:$PORT_BACKEND" 2>&1 | tee -a $LOG_DIR/autocannon_results.log

echo "------------------------------------------------------------"
echo "Benchmark Complete."
