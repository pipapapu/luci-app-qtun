#!/bin/sh
# /etc/qtun/action/stop.sh
# Force stop all QTUN services

RUN="/etc/qtun/run"

log() {
    echo "[STOP] $1"
}

kill_pid() {
    FILE="$1"

    if [ -f "$FILE" ]; then
        PID="$(cat "$FILE" 2>/dev/null)"
        if [ -n "$PID" ]; then
            kill "$PID" 2>/dev/null
            sleep 1
            kill -9 "$PID" 2>/dev/null
        fi
        rm -f "$FILE"
    fi
}

log "Stopping all QTUN services..."

# Kill by PID
kill_pid "$RUN/zivpn.pid"
kill_pid "$RUN/clash.pid"
kill_pid "$RUN/ssh.pid"

# Kill stray processes
killall zivpn 2>/dev/null
killall clash 2>/dev/null
killall ssh-core 2>/dev/null

# Clear routing
/etc/qtun/action/routing.sh stop 2>/dev/null

# Cleanup temp
rm -rf "$RUN/workers/"*
rm -f "$RUN"/*.log
rm -f "$RUN"/*.sock
rm -f "$RUN"/*.lock

log "QTUN fully stopped and cleaned"