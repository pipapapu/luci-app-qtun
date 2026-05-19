local fs = require "nixio.fs"

m = Map("qtun", "QTUN - Tunnel Configuration")

m.description = [[
<style type="text/css">
    @media screen and (max-width: 600px) {
        .cbi-value { display: flex !important; flex-direction: column !important; }
        .cbi-value-title { width: 100% !important; text-align: left !important; }
        .cbi-value-field { width: 100% !important; margin: 0 !important; }
    }
</style>
<div style="padding: 10px; background: #fff3cd; border-left: 5px solid #ffecb5; color: #856404; margin-bottom: 15px;">
    <strong>Info:</strong> Untuk mengedit config silakan pilih dulu <strong>Config Mode</strong> config yang mana yang akan di edit.
</div>
]]

s = m:section(NamedSection, "main", "global", "Edit Konfigurasi")
s.addremove = false

-- Dropdown Mode
mode = s:option(ListValue, "mode_selector", "Config Mode")
mode:value("ssh", "SSH Direct")
mode:value("zivpn", "ZiVPN (UDP)")

-- Ambil mode aktif dari sistem
local active_mode = m.uci:get("qtun", "main", "mode") or "zivpn"
mode.default = active_mode

-- Mencegah dropdown menulis langsung ke file /etc/config/qtun
function mode.write() return end

-- FUNGSI PENGAMAN: Memuat sub-module dengan aman (Safe Load)
local function safe_load(file_path, section, option)
    if fs.access(file_path) then
        local status, func = pcall(loadfile(file_path))
        if status and type(func) == "function" then
            pcall(func, section, option)
        end
    end
end

-- Memuat sub-module secara aman, jika file tidak ada maka sistem tidak akan crash
safe_load("/usr/lib/lua/luci/model/cbi/qtun/ssh.lua", s, mode)
safe_load("/usr/lib/lua/luci/model/cbi/qtun/mihomo.lua", s, mode)
safe_load("/usr/lib/lua/luci/model/cbi/qtun/zivpn.lua", s, mode)

return m
