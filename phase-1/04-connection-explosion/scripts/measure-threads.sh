#!/bin/bash
# Count total kernel threads for all NGINX processes in the container
# In a truly non-blocking architecture, this should remain constant regardless of load
docker exec nginx sh -c 'for pid in /proc/[0-9]*; do if grep -q nginx $pid/comm 2>/dev/null; then ls $pid/task; fi; done | wc -l'
