return function(s)

local cbi = require("luci.cbi")
local Value = cbi.Value
local Flag = cbi.Flag
local TextValue = cbi.TextValue

-- Enable HTTP Proxy
eh = s:option(Flag, "ssh_http_enable", "Enable HTTP Proxy")
eh:depends("mode_selector", "ssh")
eh.rmempty = false

-- Proxy IP
pip = s:option(Value, "ssh_proxy_ip", "Proxy IP")
pip:depends({mode_selector = "ssh", ssh_http_enable = "1"})
pip.placeholder = "192.168.1.1"
pip.datatype = "ipaddr"
pip.write = function() end

-- Proxy Port
pport = s:option(Value, "ssh_proxy_port", "Proxy Port")
pport:depends({mode_selector = "ssh", ssh_http_enable = "1"})
pport.datatype = "port"
pport.write = function() end

-- Payload (WAJIB TextValue, bukan Value)
pay = s:option(TextValue, "ssh_payload", "Payload")
pay:depends({mode_selector = "ssh", ssh_http_enable = "1"})
pay.rows = 5
pay.wrap = "off"

-- optional default payload
pay.default = "CONNECT [host_port] HTTP/1.1\\r\\nHost: [host_port]\\r\\n\\r\\n"
pay.write = function() end

-- Server Host
host = s:option(Value, "ssh_host", "Server Host")
host:depends("mode_selector", "ssh")
host.datatype = "host"
host.write = function() end
host.remove = function() end

-- Port
port = s:option(Value, "ssh_port", "Server Port")
port:depends("mode_selector", "ssh")
port.datatype = "port"
port.default = "22"
port.write = function() end

-- Username
user = s:option(Value, "ssh_user", "Username")
user:depends("mode_selector", "ssh")
user.write = function() end

-- Password
pass = s:option(Value, "ssh_pass", "Password")
pass:depends("mode_selector", "ssh")
pass.password = true
pass.write = function() end

-- UDPGW
udpgw = s:option(Value, "ssh_udpgw", "UDPGW Port")
udpgw:depends("mode_selector", "ssh")
udpgw.datatype = "port"
udpgw.default = "7300"
udpgw.write = function() end

end