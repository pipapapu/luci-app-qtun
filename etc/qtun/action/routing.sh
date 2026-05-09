#!/bin/sh
# /etc/qtun/action/routing.sh
# QTUN Routing Engine
# Redirect:
# Router local traffic + Hotspot client traffic -> Mihomo (7890)
# DNS -> Clash DNS (1053)

CLASH_PORT="7892"
DNS_PORT="1053"

# Auto ambil ZiVPN server dari UCI
SERVER_IP="$(uci -q get qtun.main.z_server | cut -d':' -f1)"

QTUN_CHAIN="QTUN"
QTUN_DNS_CHAIN="QTUN_DNS"

log() {
    /etc/qtun/action/logs.sh process "$1"
}

create_chains() {
    iptables -t nat -N $QTUN_CHAIN 2>/dev/null
    iptables -t nat -N $QTUN_DNS_CHAIN 2>/dev/null
}

flush_chains() {
    iptables -t nat -F $QTUN_CHAIN 2>/dev/null
    iptables -t nat -F $QTUN_DNS_CHAIN 2>/dev/null
}

delete_hooks() {
    iptables -t nat -D OUTPUT -p tcp -j $QTUN_CHAIN 2>/dev/null
    iptables -t nat -D PREROUTING -i br-lan -p tcp -j $QTUN_CHAIN 2>/dev/null

    iptables -t nat -D OUTPUT -p udp --dport 53 -j $QTUN_DNS_CHAIN 2>/dev/null
    iptables -t nat -D OUTPUT -p tcp --dport 53 -j $QTUN_DNS_CHAIN 2>/dev/null

    iptables -t nat -D PREROUTING -i br-lan -p udp --dport 53 -j $QTUN_DNS_CHAIN 2>/dev/null
    iptables -t nat -D PREROUTING -i br-lan -p tcp --dport 53 -j $QTUN_DNS_CHAIN 2>/dev/null
}

destroy_chains() {
    iptables -t nat -X $QTUN_CHAIN 2>/dev/null
    iptables -t nat -X $QTUN_DNS_CHAIN 2>/dev/null
}

apply_bypass_rules() {
    # Core local bypass
    iptables -t nat -A $QTUN_CHAIN -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A $QTUN_CHAIN -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A $QTUN_CHAIN -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A $QTUN_CHAIN -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A $QTUN_CHAIN -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A $QTUN_CHAIN -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A $QTUN_CHAIN -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A $QTUN_CHAIN -d 240.0.0.0/4 -j RETURN

    # Jangan loop ke ZiVPN server
    [ -n "$SERVER_IP" ] && iptables -t nat -A $QTUN_CHAIN -d $SERVER_IP -j RETURN

    # Jangan loop ke local proxy ports
    iptables -t nat -A $QTUN_CHAIN -p tcp --dport 1080 -j RETURN
    iptables -t nat -A $QTUN_CHAIN -p tcp --dport 7890 -j RETURN
    iptables -t nat -A $QTUN_CHAIN -p tcp --dport 9090 -j RETURN
    iptables -t nat -A $QTUN_CHAIN -p tcp --dport 1053 -j RETURN
}

apply_redirect_rules() {
    # Semua TCP -> Clash
    iptables -t nat -A $QTUN_CHAIN -p tcp -j REDIRECT --to-ports $CLASH_PORT

    # DNS -> Clash DNS
    iptables -t nat -A $QTUN_DNS_CHAIN -p udp --dport 53 -j REDIRECT --to-ports $DNS_PORT
    iptables -t nat -A $QTUN_DNS_CHAIN -p tcp --dport 53 -j REDIRECT --to-ports $DNS_PORT
}

apply_hooks() {
    # Router sendiri
    iptables -t nat -A OUTPUT -p tcp -j $QTUN_CHAIN

    # Client hotspot
    iptables -t nat -A PREROUTING -i br-lan -p tcp -j $QTUN_CHAIN

    # DNS Router
    iptables -t nat -A OUTPUT -p udp --dport 53 -j $QTUN_DNS_CHAIN
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j $QTUN_DNS_CHAIN

    # DNS Client hotspot
    iptables -t nat -A PREROUTING -i br-lan -p udp --dport 53 -j $QTUN_DNS_CHAIN
    iptables -t nat -A PREROUTING -i br-lan -p tcp --dport 53 -j $QTUN_DNS_CHAIN
}

start_routing() {
    log "Applying iptables rules..."

    stop_routing

    create_chains
    flush_chains

    apply_bypass_rules
    apply_redirect_rules
    apply_hooks

    log "iptables active"
}

stop_routing() {
    log "Removing iptables rules..."

    delete_hooks
    flush_chains
    destroy_chains

    log "iptables stopped"
}

status_routing() {
    log "iptables NAT table:"
    iptables -t nat -L $QTUN_CHAIN -n --line-numbers 2>/dev/null || log "QTUN chain not found"

    echo ""
    log "DNS NAT table:"
    iptables -t nat -L $QTUN_DNS_CHAIN -n --line-numbers 2>/dev/null || log "QTUN_DNS chain not found"
}

case "$1" in
    start)
        start_routing
        ;;
    stop)
        stop_routing
        ;;
    restart)
        stop_routing
        sleep 1
        start_routing
        ;;
    status)
        status_routing
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac