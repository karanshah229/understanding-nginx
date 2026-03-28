#!/bin/bash
# Count ESTABLISHED connections INSIDE the NGINX container (Architect Grade)
# We pull directly from /proc/net/tcp to avoid dependencies on netstat/ss
# 1F90 is the hex representation of port 8080
# ' 01 ' is the hex state for ESTABLISHED
docker exec nginx sh -c "grep ' 01 ' /proc/net/tcp | grep ':1F90' | wc -l"
