#!/bin/bash

# Target URL (Mapped via localhost if running from host, or nginx if inside docker)
TARGET_URL=${1:-"http://localhost:8080/"}

echo "------------------------------------------------------------"
echo "Phase 1: Warming up (Low Concurrency, 5s)"
echo "------------------------------------------------------------"
npx autocannon -c 10 -d 20 $TARGET_URL

echo ""
echo "------------------------------------------------------------"
echo "Phase 2: SUDDEN SPIKE (High Concurrency, 10s)"
echo "------------------------------------------------------------"
npx autocannon -c 200 -d 20 $TARGET_URL

echo ""
echo "Done. Look at the p99 latency vs p50 in Phase 2 results."
