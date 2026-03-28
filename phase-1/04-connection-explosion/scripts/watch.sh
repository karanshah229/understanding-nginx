#!/bin/bash
# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use printf for better portability with 'watch' and macOS sh
watch -n 1 "printf 'FDs: '; $SCRIPT_DIR/measure-fd.sh; printf 'Connections: '; $SCRIPT_DIR/measure-connections.sh"
