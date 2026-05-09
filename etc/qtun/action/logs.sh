#!/bin/sh
# /etc/qtun/action/logs.sh

MAX_LINES=100
TRIM_TO=80
RUN_DIR="/etc/qtun/run"

[ -d "$RUN_DIR" ] || mkdir -p "$RUN_DIR"

trim_file() {
    file="$1"

    [ -f "$file" ] || return 0

    lines=$(wc -l < "$file" 2>/dev/null)

    if [ "$lines" -gt "$MAX_LINES" ]; then
        tail -n "$TRIM_TO" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
}

log_append() {
    file="$1"
    msg="$2"
    timestamp=$(date '+%H:%M:%S')

    echo "[$timestamp] $msg" >> "$file"

    trim_file "$file"
}

case "$1" in
    process)
        log_append "$RUN_DIR/qtun_live.log" "$2"
        echo "[QTUN] $2"
        ;;
    rotate)
        target_file="$2"
        trim_file "$target_file"
        ;;
    clear)
        : > "$RUN_DIR/qtun_live.log"
        : > "$RUN_DIR/zivpn.log"
        : > "$RUN_DIR/q-load.log"
        : > "$RUN_DIR/clash.log"
        ;;
    *)
        echo "Usage: $0 {process|rotate|clear}"
        exit 1
        ;;
esac