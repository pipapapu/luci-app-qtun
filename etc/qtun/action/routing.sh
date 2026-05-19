#!/bin/sh
# /etc/qtun/action/routing.sh
# QTUN Routing Engine (Modern fw4/nftables Edition)
# Dioptimalkan Khusus untuk OpenWrt Baru & Modem HP Android

# Port Socks5 bawaan ZiVPN sesuai config.json Anda
SOCKS_PORT="1080"
DNS_PORT="1053"

SERVER_IP="$(uci -q get qtun.main.z_server | cut -d':' -f1)"

log() {
    /etc/qtun/action/logs.sh process "$1"
}

# Fungsi otomatis mencari interface modem HP Android Anda (usb0 atau rndis0)
get_android_device() {
    local dev=""
    for d in usb0 rndis0 wwan0; do
        if [ -d "/sys/class/net/$d" ]; then
            dev="$d"
            break
        fi
    done
    echo "$dev"
}

start_routing() {
    log "Mengonfigurasi aturan nftables via fw4..."
    stop_routing

    local android_dev="$(get_android_device)"
    
    # 1. Buka jalur forwarding dasar untuk kartu jaringan ZiVPN (tun0)
    nft add rule inet fw4 forward oifname "tun*" accept 2>/dev/null
    nft add rule inet fw4 forward iifname "tun*" accept 2>/dev/null
    nft add rule inet fw4 srcnat oifname "tun*" masquerade 2>/dev/null

    # 2. Jika terdeteksi menggunakan Tethering HP Android, buka jalur jembatannya
    if [ -n "$android_dev" ]; then
        log "Modem HP Android terdeteksi pada interface: $android_dev"
        nft add rule inet fw4 forward oifname "$android_dev" accept 2>/dev/null
        nft add rule inet fw4 forward iifname "$android_dev" accept 2>/dev/null
        nft add rule inet fw4 srcnat oifname "$android_dev" masquerade 2>/dev/null
    else
        log "Menggunakan interface WAN standar (bukan HP Android)"
    fi

    # 3. Membuat aturan pembelokan (Redirect) ke Socks5 ZiVPN (Port 1080)
    # Membuat chain kustom di nftables nat agar tidak mengacaukan firewall utama
    nft create chain inet fw4 qtun_redirect { type nat hook prerouting priority dstnat \; } 2>/dev/null
    nft flush chain inet fw4 qtun_redirect 2>/dev/null

    # Aturan Bypass agar IP Lokal/IP Server tidak ikut terbelokkan (mencegah loop)
    nft add rule inet fw4 qtun_redirect ip daddr { 127.0.0.0/8, 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12 } return 2>/dev/null
    [ -n "$SERVER_IP" ] && nft add rule inet fw4 qtun_redirect ip daddr $SERVER_IP return 2>/dev/null

    # Belokkan semua lalu lintas TCP dari client ke Port ZiVPN
    nft add rule inet fw4 qtun_redirect iifname "br-lan" ip protocol tcp redirect to :$SOCKS_PORT 2>/dev/null

    log "Aturan routing qtun (fw4) berhasil diaktifkan"
}

stop_routing() {
    log "Menghapus aturan nftables qtun..."

    # Hapus chain kustom redirect
    nft delete chain inet fw4 qtun_redirect 2>/dev/null
    
    log "Aturan routing qtun berhasil dibersihkan"
}

status_routing() {
    local android_dev="$(get_android_device)"
    log "Status Perangkat Modem Android: ${android_dev:-Tidak terdeteksi}"
    log "Memeriksa tabel nftables qtun:"
    nft list chain inet fw4 qtun_redirect 2>/dev/null || log "Chain qtun_redirect tidak aktif"
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
