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
    entry({"admin", "services", "qtun", "get_log"}, call("action_get_log"), nil).leaf = true
    entry({"qtun", "ipinfo"}, call("action_ipinfo")).leaf = true
end

-- STATUS (Optimasi Ringan & Bebas Bug)
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

    -- Menggunakan pembacaan file langsung (fs.readfile) agar tidak membebani CPU seperti perintah 'tail'
    local log_path = "/etc/qtun/run/qtun.log"
    if mode == "zivpn" then
        log_path = fs.access("/etc/qtun/run/zivpn.log") and "/etc/qtun/run/zivpn.log" or "/etc/qtun/run/clash.log"
    end
    
    local log_content = "Belum ada log."
    if fs.access(log_path) then
        local raw_log = fs.readfile(log_path) or ""
        log_content = string.sub(raw_log, -2000) -- Mengambil 2000 karakter terakhir dengan cepat
    end

    local clash_running = (sys.call("pgrep clash >/dev/null") == 0) or (sys.call("pgrep mihomo >/dev/null") == 0)

    -- Penggabungan data yang benar tanpa deklarasi ganda
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

-- SAVE CONFIG (FIXED: Menambahkan respon kembalian JSON)
function action_set_config()
    local http = require "luci.http"
    local uci = require("luci.model.uci").cursor()

    local mode = http.formvalue("mode")
    local enabled = http.formvalue("enabled")

    if mode then uci:set("qtun", "main", "mode", mode) end
    if enabled then uci:set("qtun", "main", "enabled", enabled) end

    local success = uci:commit("qtun")
    
    luci.http.prepare_content("application/json")
    luci.http.write_json({ success = true, saved = success })
end

-- GET LOG
function action_get_log()
    local fs = require "nixio.fs"
    local uci = require("luci.model.uci").cursor()

    local mode = uci:get("qtun", "main", "mode") or "zivpn"
    local core_log = "Belum ada log Core."

    if mode == "zivpn" then
        core_log = fs.readfile("/etc/qtun/run/zivpn.log") or "Belum ada log Core."
    elseif mode == "ssh" or mode == "ssh_ws" or mode == "ssh_ssl" then
        core_log = fs.readfile("/etc/qtun/run/ssh.log") or "Belum ada log Core."
    elseif mode == "clash" then
        core_log = fs.readfile("/etc/qtun/run/clash.log") or "Belum ada log Core."
    end

    local data = {
        process = fs.readfile("/etc/qtun/run/qtun_live.log") or "Belum ada log proses.",
        core = core_log,
        clash = fs.readfile("/etc/qtun/run/clash.log") or "Belum ada log Clash."
    }

    luci.http.prepare_content("application/json")
    luci.http.write_json(data)
end

-- IP INFO (Optimasi Timeout 2 Detik agar Internet Tidak Macet)
function action_ipinfo()
    local sys = require "luci.sys"
    -- Mengubah max-time dari 8 detik menjadi 2 detik agar tidak membuat hang jaringan router
    local result = sys.exec("curl -s --max-time 2 http://ip-api.com/json 2>/dev/null")

    if result == nil or result == "" then
        result = '{"status":"fail","message":"Koneksi VPN belum tersambung"}'
    end

    luci.http.prepare_content("application/json")
    luci.http.write(result)
end
