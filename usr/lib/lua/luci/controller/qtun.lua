-- Berkas Pengontrol LuCI Baru untuk QTUN
-- Kompatibel dengan OpenWrt Modern (Ucode Bridge)

local fs = require "nixio.fs"

-- 1. Inisialisasi objek pengontrol sebagai blok lokal
local m = {}

-- 2. Fungsi mendaftarkan menu utama
function m.index()
    -- Memastikan menu hanya muncul jika berkas konfigurasi qtun ada di router
    if not fs.access("/etc/config/qtun") then
        return
    end

    -- Mendaftarkan menu QTUN di bawah tab "Services" (Layanan)
    entry({"admin", "services", "qtun"}, cbi("qtun/settings"), _("QTUN"), 60).dependent = true
    
    -- Mendaftarkan jalur API untuk mengecek status aplikasi di latar belakang
    entry({"admin", "services", "qtun", "status"}, call("action_status")).leaf = true
end

-- 3. Fungsi logika untuk mengambil status
function m.action_status()
    local luci = require "luci.util"
    -- Logika pengecekan status di sini
end

-- 4. Wajib mengembalikan objek pengontrol di akhir baris
return m
