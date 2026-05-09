module("luci.controller.qtun", package.seeall)

function index()
    local page = entry({"admin", "services", "qtun"}, alias("admin", "services", "qtun", "dashboard"), _("QTUN"), 10)
    page.dependent = true

    entry({"admin", "services", "qtun", "dashboard"}, template("qtun/dashboard"), _("Dashboard"), 1)
    entry({"admin", "services", "qtun", "config"}, cbi("qtun/config"), _("Tunnel Config"), 2)
    -- entry({"admin", "services", "qtun", "routing"}, cbi("qtun/routing"), _("Routing & Rules"), 3)
    -- entry({"admin", "services", "qtun", "advanced"}, cbi("qtun/advanced"), _("Advanced Tools"), 4)
    entry({"admin", "services", "qtun", "logs"}, template("qtun/logs"), _("Logs & Terminal"), 5)

    -- API
    entry({"admin", "services", "qtun", "status"}, call("action_status")).leaf = true
    entry({"admin", "services", "qtun", "start"}, call("action_start")).leaf = true
    entry({"admin", "services", "qtun", "stop"}, call("action_stop")).leaf = true
    entry({"admin", "services", "qtun", "restart"}, call("action_restart")).leaf = true
    entry({"admin", "services", "qtun", "set_config"}, call("action_set_config")).leaf = true
-- API untuk mengambil data log via AJAX
    entry({"admin", "services", "qtun", "get_log"}, call("action_get_log"), nil).leaf = true
-- PUBLIC IP API (NO LOGIN)
    entry({"qtun", "ipinfo"}, call("action_ipinfo")).leaf = true
end

-- STATUS (Versi Ringan)
function action_status()
    local sys = require "luci.sys"
    local uci = require("luci.model.uci").cursor()

    local mode = uci:get("qtun", "main", "mode") or "zivpn"
    local enabled = uci:get("qtun", "main", "enabled") or "0"
    local running = false

    if mode == "zivpn" then
        running = (sys.call("pgrep zivpn >/dev/null") == 0) or (sys.call("pgrep mihomo >/dev/null") == 0)
    elseif mode == "ssh" or mode == "ssh_ws" or mode == "ssh_ssl" then
        running = (sys.call("pgrep ssh >/dev/null") == 0) or (sys.call("pgrep ssh-core >/dev/null") == 0)
    end

    local log = ""
    if mode == "zivpn" then
        log = sys.exec("tail -n 30 /etc/qtun/run/zivpn.log 2>/dev/null")
        if log == "" then log = sys.exec("tail -n 30 /etc/qtun/run/clash.log 2>/dev/null") end
    else
        log = sys.exec("tail -n 30 /etc/qtun/run/qtun.log 2>/dev/null")
    end

    local data = {
        running = running,
        mode = mode,
        enabled = enabled,
        log = log
    }


    local clash_running = (sys.call("pgrep clash >/dev/null") == 0)
        or (sys.call("pgrep mihomo >/dev/null") == 0)

    local data = {
        running = running,
        clash_running = clash_running,   -- FIXED
        mode = mode,
        enabled = enabled,
        log = log
    }

    luci.http.prepare_content("application/json")
    luci.http.write_json(data)
end

-- START
function action_start()
    local sys = require "luci.sys"

    sys.call("/etc/qtun/action/qtun.sh start >/dev/null 2>&1 &")

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = true,
        action = "start"
    })
end

-- STOP
function action_stop()
    local sys = require "luci.sys"

    sys.call("/etc/qtun/action/qtun.sh stop >/dev/null 2>&1 &")

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = true,
        action = "stop"
    })
end

-- RESTART
function action_restart()
    local sys = require "luci.sys"

    sys.call("/etc/qtun/action/qtun.sh restart >/dev/null 2>&1 &")

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = true,
        action = "restart"
    })
end

-- SAVE CONFIG (mode + autostart)
function action_set_config()
    local http = require "luci.http"
    local uci = require("luci.model.uci").cursor()

    local mode = http.formvalue("mode")
    local enabled = http.formvalue("enabled")

    if mode then
        uci:set("qtun", "main", "mode", mode)
    end

    if enabled then
        uci:set("qtun", "main", "enabled", enabled)
    end

    uci:commit("qtun")
end

-- FIX action_get_log TANPA qtun.log
function action_get_log()
    local fs = require "nixio.fs"
    local uci = require("luci.model.uci").cursor()

    local mode = uci:get("qtun", "main", "mode") or "zivpn"

    local core_log = "Belum ada log Core."

    if mode == "zivpn" then
        core_log = fs.readfile("/etc/qtun/run/zivpn.log")
            or "Belum ada log Core."

    elseif mode == "ssh" or mode == "ssh_ws" or mode == "ssh_ssl" then
        core_log = fs.readfile("/etc/qtun/run/ssh.log")
            or "Belum ada log Core."

    elseif mode == "clash" then
        core_log = fs.readfile("/etc/qtun/run/clash.log")
            or "Belum ada log Core."
    end

    local data = {
        process = fs.readfile("/etc/qtun/run/qtun_live.log")
            or "Belum ada log proses.",

        core = core_log,

        clash = fs.readfile("/etc/qtun/run/clash.log")
            or "Belum ada log Clash."
    }

    luci.http.prepare_content("application/json")
    luci.http.write_json(data)
end

function action_ipinfo()
    local sys = require "luci.sys"

    local result = sys.exec("curl -s --max-time 8 http://ip-api.com/json 2>/dev/null")

    if result == nil or result == "" then
        result = '{"status":"fail","message":"Unable to fetch IP info"}'
    end

    luci.http.prepare_content("application/json")
    luci.http.write(result)
end