#!/bin/bash
set -e
ulimit -c unlimited

# Decide mode based on first argument
if [[ "$1" == "--debug" ]]; then
    shift
    echo "Launching Amulet in DEBUG mode..."
    exec python -m amulet_map_editor amulet-debug "$@"
else
    echo "Launching Amulet in NORMAL mode..."
    exec python -m amulet_map_editor "$@"
fi
