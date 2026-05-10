# luci-app-qtun

LuCI interface untuk Q-Tunneling dengan dukungan:

- ZiVPN (UDP)
- Clash / Mihomo
- Q-Load Core
- SSH *(Coming Soon)*
- SSH WebSocket (SSH-WS) *(Coming Soon)*
- SSH SSL (SSH-SSL) *(Coming Soon)*

Dirancang untuk OpenWrt dengan auto-download core saat build dan integrasi penuh ke LuCI.

---

<h1 align="center">
  <img src="https://raw.githubusercontent.com/QcomWrt/luci-app-qtun/master/img/main.png" alt="QTUN Dashboard" width="100%">
  <br>QTUN Dashboard
</h1>

<h1 align="center">
  <img src="https://raw.githubusercontent.com/QcomWrt/luci-app-qtun/master/img/yacd.png" alt="YACD" width="100%">
  <br>YACD
</h1>

<h1 align="center">
  <img src="https://raw.githubusercontent.com/QcomWrt/luci-app-qtun/master/img/logs.png" alt="QTUN Dashboard Logs" width="100%">
  <br>QTUN Dashboard Logs
</h1>

---

## 📦 Instalasi Package (.ipk)

### Metode SCP

```bash
scp luci-app-qtun.ipk root@192.168.1.1:/tmp/
```

### Install

```bash
opkg update
opkg install /tmp/luci-app-qtun.ipk
```

### Restart LuCI

```bash
/etc/init.d/uhttpd restart
```

### Atau reboot

```bash
reboot
```

---

## 📦 Install Dependency Manual (jika diperlukan)

```bash
opkg update
opkg install luci bash curl ca-bundle ca-certificates gunzip jq
```

---

## 🚀 Fitur Utama

### Auto Download Core
- Mihomo Core
- Q-Load Core
- ZiVPN Core

### LuCI Features
- LuCI Web UI
- Multi tunnel support
- Config management
- Auto boot
- Script action modular

---

## 🛠 Arsitektur Support

- AMD64 / x86_64
- ARM64 / aarch64
- ARM / armv7

---

## 🧠 Troubleshooting

### Cek log

```bash
logread -f
```

### Cek service

```bash
/etc/qtun/action/qtun.sh status
```

### Restart service

```bash
/etc/qtun/action/qtun.sh restart
```

---

## ❌ Uninstall

```bash
opkg remove luci-app-qtun
rm -rf /etc/qtun
```

---

## 🔖 Release

Build release tersedia di tab **Releases**:

https://github.com/QcomWrt/luci-app-qtun/releases

---

## 📜 License

* [MIT License](https://github.com/QcomWrt/luci-app-qtun/blob/master/LICENSE)

## Core / Binaries

* Zivpn [Zivpn](https://github.com/zahidbd2/udp-zivpn) by [zahidbd2](https://github.com/zahidbd2)

* Q-load [Q-load](https://github.com/QcomWrt/Q-load) by [QcomWrt](https://github.com/QcomWrt)

* Clash [Mihomo](https://github.com/MetaCubeX/mihomo) by [MetaCubeX](https://github.com/MetaCubeX)

---

## 👤 Maintainer

**Azy / QcomWrt**