module("luci.controller.qtun", package.seeall)

function index()
    local page = entry({"admin", "services", "qtun"}, alias("admin", "services", "qtun", "dashboard"), _("QTUN"), 10)
    page.dependent = true

    entry({"admin", "services", "qtun", "dashboard"}, template("qtun/dashboard"), _("Dashboard"), 1)
    entry({"admin", "services", "qtun", "config"}, cbi("qtun/config"), _("Tunnel Config"), 2)
    entry({"admin", "services", "qtun", "logs"}, template("qtun/logs"), _("Logs & Terminal"), 5)

    -- API
    entry({"admin", "services", "qtun", "status"}, call("action_status")).leaf = true
    entry({"admin", "services", "qtun", "start"}, call("action_start")).leaf = true
    entry({"admin", "services", "qtun", "stop"}, call("action_stop")).leaf = true
    entry({"admin", "services", "qtun", "restart"}, call("action_restart")).leaf = true
    entry({"admin", "services", "qtun", "set_config"}, call("action_set_config")).leaf = true
    entry({"admin", "services", "qtun", "get_log"}, call("action_get_log")).leaf = true
    entry({"qtun", "ipinfo"}, call("action_ipinfo")).leaf = true
end

-- FUNGSI BANTUAN: Membaca log dengan super ringan (Tanpa beban CPU 'tail' dan Tanpa risiko RAM penuh)
local function read_tail_log(filepath, bytes)
    local fs = require "nixio.fs"
    local stat = fs.stat(filepath)
    if not stat or stat.size == 0 then
        return "Belum ada log."
    end

    local fd = fs.open(filepath, "r")
    if not fd then
        return "Gagal membaca log."
    end

    -- Lompat langsung ke posisi terakhir dikurangi batas bytes
    local seek_pos = stat.size > bytes and (stat.size - bytes) or 0
    fd:seek(seek_pos, "set")
    
    local content = fd:read(bytes) or ""
    fd:close()
    return content
end

-- STATUS (Optimasi Ringan & Bebas Bug Memori)
function action_status()
    local sys = require "luci.sys"
    local uci = require("luci.model.uci").cursor()
    local fs = require "nixio.fs"

    local mode = uci:get("qtun", "main", "mode") or "zivpn"
    local enabled = uci:get("qtun", "main", "enabled") or "0"
    local running = false

    if mode == "zivpn" then
        running = (sys.call("pgrep zivpn >/dev/null") == 0) or (sys.call("pgrep mihomo >/dev/null") == 0)
    elseif mode == "ssh" or mode == "ssh_ws" or mode == "ssh_ssl" then
        running = (sys.call("pgrep ssh >/dev/null") == 0) or (sys.call("pgrep ssh-core >/dev/null") == 0)
    end

    local log_path = "/etc/qtun/run/qtun.log"
    if mode == "zivpn" then
        log_path = fs.access("/etc/qtun/run/zivpn.log") and "/etc/qtun/run/zivpn.log" or "/etc/qtun/run/clash.log"
    end
    
    -- Membaca 2000 bytes terakhir menggunakan fungsi bantuan yang jauh lebih aman
    local log_content = read_tail_log(log_path, 2000)

    local clash_running = (sys.call("pgrep -f clash >/dev/null") == 0) or (sys.call("pgrep -f mihomo >/dev/null") == 0)

    local data = {
        running = running,
        clash_running = clash_running,
        mode = mode,
        enabled = enabled,
        log = log_content
    }

    luci.http.prepare_content("application/json")
    luci.http.write_json(data)
end

-- START
function action_start()
    local sys = require "luci.sys"
    sys.call("/etc/qtun/action/qtun.sh start >/dev/null 2>&1 &")

    luci.http.prepare_content("application/json")
    luci.http.write_json({ success = true, action = "start" })
end

-- STOP
function action_stop()
    local sys = require "luci.sys"
    sys.call("/etc/qtun/action/qtun.sh stop >/dev/null 2>&1 &")

    luci.http.prepare_content("application/json")
    luci.http.write_json({ success = true, action = "stop" })
end

-- RESTART
function action_restart()
    local sys = require "luci.sys"
    sys.call("/etc/qtun/action/qtun.sh restart >/dev/null 2>&1 &")

    luci.http.prepare_content("application/json")
    luci.http.write_json({ success = true, action = "restart" })
end

-- SAVE CONFIG 
function action_set_config()
    local http = require "luci.http"
    local uci = require("luci.model.uci").cursor()

    local mode = http.formvalue("mode")
    local enabled = http.formvalue("enabled")

    -- Sanitasi ringan agar tidak disalahgunakan
    if mode and mode:match("^[a-zA-Z0-9_]+$") then 
        uci:set("qtun", "main", "mode", mode) 
    end
    if enabled == "1" or enabled == "0" then 
        uci:set("qtun", "main", "enabled", enabled) 
    end

    local success = uci:commit("qtun")
    
    luci.http.prepare_content("application/json")
    luci.http.write_json({ success = true, saved = success })
end

-- GET LOG (Diubah agar tidak membuat RAM penuh)
function action_get_log()
    local uci = require("luci.model.uci").cursor()
    local mode = uci:get("qtun", "main", "mode") or "zivpn"
    
    local core_log_path = "/etc/qtun/run/qtun.log"
    if mode == "zivpn" then
        core_log_path = "/etc/qtun/run/zivpn.log"
    elseif mode == "ssh" or mode == "ssh_ws" or mode == "ssh_ssl" then
        core_log_path = "/etc/qtun/run/ssh.log"
    elseif mode == "clash" then
        core_log_path = "/etc/qtun/run/clash.log"
    end

    -- Gunakan fungsi read_tail_log agar aman dan ringan
    local data = {
        process = read_tail_log("/etc/qtun/run/qtun_live.log", 3000),
        core = read_tail_log(core_log_path, 5000),
        clash = read_tail_log("/etc/qtun/run/clash.log", 3000)
    }

    luci.http.prepare_content("application/json")
    luci.http.write_json(data)
end

-- IP INFO
function action_ipinfo()
    local sys = require "luci.sys"
    local result = sys.exec("curl -s --max-time 2 http://ip-api.com/json 2>/dev/null")

    if result == nil or result == "" then
        result = '{"status":"fail","message":"Koneksi VPN belum tersambung"}'
    end

    luci.http.prepare_content("application/json")
    luci.http.write(result)
end
