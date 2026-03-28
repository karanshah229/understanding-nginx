#!/bin/bash
# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use printf for better portability with 'watch' and macOS sh
# Now includes Threads to prove the Non-Blocking architecture
watch -n 1 "printf 'FDs: '; $SCRIPT_DIR/measure-fd.sh; printf 'Threads: '; $SCRIPT_DIR/measure-threads.sh; printf 'Connections: '; $SCRIPT_DIR/measure-connections.sh"
