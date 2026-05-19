#!/bin/sh
# /etc/qtun/action/zivpn.sh
# ZiVPN Launcher (Optimized for Android Tethering & Single Worker)

set -u

BASE="/etc/qtun"
RUN="$BASE/run"

# Core binaries
ZIVPN_BIN="$BASE/core/zivpn"
ZIVPN_CFG="$BASE/config/zivpn/config.json"

# PID & Logs
ZIVPN_PID="$RUN/zivpn.pid"
ZIVPN_LOG="$RUN/zivpn.log"

mkdir -p "$RUN"

log() {
    /etc/qtun/action/logs.sh process "$1"
}

is_running() {
    [ -f "$1" ] || return 1
    PID="$(cat "$1" 2>/dev/null)"
    [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null
}

stop_existing() {
    log "Menghentikan semua proses latar belakang lama..."
    if [ -f "$ZIVPN_PID" ]; then
        PID="$(cat "$ZIVPN_PID" 2>/dev/null)"
        [ -n "$PID" ] && kill "$PID" 2>/dev/null
        rm -f "$ZIVPN_PID"
    fi
    killall -9 zivpn q-load clash mihomo 2>/dev/null
    sleep 1
}

start_zivpn() {
    log "Memulai ZiVPN (Mode Single Worker untuk HP Android)..."

    if [ ! -x "$ZIVPN_BIN" ]; then
        log "Error: Binari ZiVPN tidak ditemukan di $ZIVPN_BIN"
        return 1
    fi

    if [ ! -f "$ZIVPN_CFG" ]; then
        log "Error: Konfigurasi ZiVPN tidak ditemukan di $ZIVPN_CFG"
        return 1
    fi

    : > "$ZIVPN_LOG"

    # Menjalankan 1 proses ZiVPN murni pada Port standar 1080
    "$ZIVPN_BIN" -s 'hu``hqb`c' --config "$ZIVPN_CFG" > "$ZIVPN_LOG" 2>&1 &
    PID=$!

    echo "$PID" > "$ZIVPN_PID"

    # Pengecekan apakah proses berhasil mengunci port 1080
    READY=0
    for t in $(busybox seq 1 10); do
        sleep 1
        if ! kill -0 "$PID" 2>/dev/null; then
            break
        fi
        if netstat -tunlp 2>/dev/null | grep -q "1080"; then
            READY=1
            break
        fi
    done

    if [ "$READY" -eq 1 ]; then
        log "ZiVPN sukses berjalan pada port :1080 (PID $PID)"
        return 0
    fi

    log "ZiVPN gagal berjalan. Periksa isi file log di $ZIVPN_LOG"
    kill "$PID" 2>/dev/null
    rm -f "$ZIVPN_PID"
    return 1
}

case "${1:-start}" in
    start)
        stop_existing
        start_zivpn
        ;;
    stop)
        stop_existing
        log "Layanan ZiVPN berhasil dihentikan"
        ;;
    restart)
        stop_existing
        sleep 1
        start_zivpn
        ;;
    status)
        is_running "$ZIVPN_PID" && log "ZiVPN: RUNNING" || log "ZiVPN: STOPPED"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
