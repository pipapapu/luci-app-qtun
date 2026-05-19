return function(s, mode_selector) 

    local cbi = require("luci.cbi")
    local Value = cbi.Value
    local Flag = cbi.Flag

    local fs = require "nixio.fs"
    local json = require "luci.jsonc"

    -- Path khusus ZiVPN
    local base_dir = "/etc/qtun/config/zivpn"
    local path = base_dir .. "/config.json"

    -- Load existing config
    local zicfg = {}
    if fs.access(path) then
        zicfg = json.parse(fs.readfile(path)) or {}
    end

    -- =========================================================
    -- BASIC ACCOUNT
    -- =========================================================

    local srv = s:option(Value, "z_server", "Server IP / Host")
    srv.default = zicfg.server and zicfg.server:match("^(.-):") or ""
    srv:depends("mode_selector", "zivpn")
    srv.write = function() end
    srv.remove = function() end

    local ports = s:option(Value, "z_port_ranges", "Port Ranges")
    ports.default = zicfg.server and zicfg.server:match(":(.+)$") or "6000-19999"
    ports:depends("mode_selector", "zivpn")
    ports.write = function() end

    local auth = s:option(Value, "z_auth", "Password")
    auth.password = true
    auth.default = zicfg.auth or ""
    auth:depends("mode_selector", "zivpn")
    auth.write = function() end

    local obfs = s:option(Value, "z_obfs", "Obfuscation Key")
    obfs.default = zicfg.obfs or "hu``hqb`c"
    obfs:depends("mode_selector", "zivpn")
    obfs.write = function() end

    local insecure = s:option(Flag, "z_insecure", "Skip TLS Verify")
    insecure.default = (zicfg.insecure == true) and "1" or "0"
    insecure.rmempty = false
    insecure:depends("mode_selector", "zivpn")
    insecure.write = function() end

    -- =========================================================
    -- PERFORMANCE
    -- =========================================================

    local resolver = s:option(Value, "z_resolver", "Resolver DNS")
    resolver.default = zicfg.resolver or "8.8.8.8:53"
    resolver:depends("mode_selector", "zivpn")
    resolver.write = function() end

    local down = s:option(Value, "z_down_mbps", "Download Mbps (0 = Tanpa Batasan)")
    down.datatype = "uinteger"
    down.default = zicfg.down_mbps or "0" -- Diubah ke 0 agar secara default internet tidak dicekik/dibatasi
    down:depends("mode_selector", "zivpn")
    down.write = function() end

    local up = s:option(Value, "z_up_mbps", "Upload Mbps (0 = Tanpa Batasan)")
    up.datatype = "uinteger"
    up.default = zicfg.up_mbps or "0" -- Diubah ke 0 agar secara default internet tidak dicekik/dibatasi
    up:depends("mode_selector", "zivpn")
    up.write = function() end

    -- =========================================================
    -- SAVE HOOK (FIXED: Menggunakan validasi Section ID yang Benar)
    -- =========================================================

    local old_parse = s.parse

    function s.parse(self, section, ...)
        -- Mengambil ID section yang aktif dari sistem LuCI secara dinamis
        local sid = section or "main"
        local current_mode = mode_selector:formvalue(sid)
        
        if current_mode == "zivpn" then
            local server_host = srv:formvalue(sid) or ""
            local port_range = ports:formvalue(sid) or ""

            local full_server = ""
            if server_host ~= "" then
                full_server = server_host .. ":" .. port_range
            end

            -- Mengamankan konversi angka agar tidak memicu crash %d jika form kosong
            local raw_down = down:formvalue(sid)
            local raw_up = up:formvalue(sid)
            local val_down = tonumber(raw_down) or 0
            local val_up = tonumber(raw_up) or 0

            -- Menyusun JSON secara bersih dan presisi
            local json_data = string.format([[
{
  "server": %q,
  "obfs": %q,
  "auth": %q,
  "socks5": {
    "listen": "127.0.0.1:1080"
  },
  "insecure": %s,
  "recvwindowconn": 65536,
  "recvwindow": 262144,
  "disable_mtu_discovery": true,
  "resolver": %q,
  "down_mbps": %d,
  "up_mbps": %d
}
]],
                full_server,
                obfs:formvalue(sid) or "hu``hqb`c",
                auth:formvalue(sid) or "",
                (insecure:formvalue(sid) == "1") and "true" or "false",
                resolver:formvalue(sid) or "8.8.8.8:53",
                val_down,
                val_up
            )

            -- Simpan file secara aman
            fs.mkdirr(base_dir)
            fs.writefile(path, json_data)
            
            -- Sinkronisasi juga ke UCI agar sistem utama OpenWrt tahu mode apa yang aktif
            self.map.uci:set("qtun", "main", "mode", "zivpn")
        end

        old_parse(self, section, ...)
    end

end
