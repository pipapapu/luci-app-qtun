local arg = {...}
local s = arg[1]

-- Server Settings
host = s:option(Value, "ssls_host", translate("Server Host"))
host:depends("type", "ssh_ssl")

ip = s:option(Value, "ssls_ip", translate("Server IP"))
ip:depends("type", "ssh_ssl")

port = s:option(Value, "ssls_port", translate("Server Port"))
port:depends("type", "ssh_ssl")
port.default = "443"

-- Credentials
user = s:option(Value, "ssls_user", translate("Username"))
user:depends("type", "ssh_ssl")

pass = s:option(Value, "ssls_pass", translate("Password"))
pass:depends("type", "ssh_ssl")
pass.password = true

-- SSL Specific
sni = s:option(Value, "ssls_sni", translate("SNI (Bug Host)"))
sni:depends("type", "ssh_ssl")

udpgw = s:option(Value, "ssls_udpgw", translate("UDPGW Port"))
udpgw:depends("type", "ssh_ssl")
udpgw.default = "7300"