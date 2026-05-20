#!/bin/sh
# /etc/qtun/action/routing.sh
# QTUN Routing Engine - Modem HP Android & Socks5 TPROXY Edition

SOCKS_PORT="1080"
WAN_DEV="usb0" # Interface modem HP Android Anda

log() {
    /etc/qtun/action/logs.sh process "$1"
}

start_routing() {
    log "Mengonfigurasi TPROXY nftables untuk modem HP ($WAN_DEV)..."
    stop_routing

    # 1. Daftarkan tabel routing lokal dan tanda pengenal (Marking)
    ip rule add fwmark 1 table 100 priority 100 2>/dev/null
    ip route add local default dev lo table 100 2>/dev/null

    # 2. Buat aturan rantai (Chain) kustom di nftables/fw4 agar tidak bentrok dengan firewall utama
    nft create chain inet fw4 qtun_tproxy { type filter hook prerouting priority mangle \; } 2>/dev/null
    nft flush chain inet fw4 qtun_tproxy 2>/dev/null

    # Jalur Bypass (Agar IP Lokal tidak ikut terbelokkan yang bisa bikin router hang/looping)
    nft add rule inet fw4 qtun_tproxy ip daddr { 127.0.0.0/8, 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12 } return 2>/dev/null

    # Pembelokan Utama: Ambil trafik TCP & UDP dari Wi-Fi/LAN (br-lan) lalu tembak ke Port ZiVPN (1080)
    nft add rule inet fw4 qtun_tproxy iifname "br-lan" ip protocol tcp tproxy to :$SOCKS_PORT meta mark set 1 2>/dev/null
    nft add rule inet fw4 qtun_tproxy iifname "br-lan" ip protocol udp tproxy to :$SOCKS_PORT meta mark set 1 2>/dev/null

    # 3. Berikan izin Masquerade (pembagian internet) agar lalu lintas bisa keluar via usb0
    nft add table inet fw4 { chain nat_postrouting { oifname "$WAN_DEV" masquerade } } 2>/dev/null

    ip route flush cache
    log "Aturan TPROXY (Socks5 via $WAN_DEV) berhasil diaktifkan!"
}

stop_routing() {
    log "Membersihkan aturan routing dan TPROXY..."

    # Hapus aturan firewall kustom qtun
    nft delete chain inet fw4 qtun_tproxy 2>/dev/null
    
    # Hapus IP Rule & Route lokal
    ip rule del table 100 2>/dev/null
    ip route del local default dev lo table 100 2>/dev/null
    ip route flush cache

    log "Aturan routing berhasil dibersihkan"
}

status_routing() {
    log "Memeriksa kesiapan interface modem HP ($WAN_DEV):"
    if [ -d "/sys/class/net/$WAN_DEV" ]; then
        log "Interface $WAN_DEV: TERDETEKSI DAN AKTIF"
    else
        log "Interface $WAN_DEV: TIDAK ADA (Periksa sambungan kabel USB HP Anda!)"
    fi
    nft list chain inet fw4 qtun_tproxy 2>/dev/null || log "Aturan TPROXY sedang tidak berjalan"
}

case "$1" in
    start)   start_routing ;;
    stop)    stop_routing ;;
    restart) stop_routing; sleep 1; start_routing ;;
    status)  status_routing ;;
    *)       echo "Usage: $0 {start|stop|restart|status}"; exit 1 ;;
    esac
