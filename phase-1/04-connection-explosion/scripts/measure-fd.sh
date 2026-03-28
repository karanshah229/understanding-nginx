#!/bin/bash
# Count FDs across ALL processes in the container (Master + Workers)
# This lists all FD entries for all process IDs found in /proc/
docker exec nginx sh -c 'ls /proc/[0-9]*/fd | wc -l'
