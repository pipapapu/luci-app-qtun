local arg = {...}
local s = arg[1]

-- Payload (WS CDN)
pay = s:option(TextValue, "ws_payload", translate("Websocket Payload"))
pay:depends("type", "ssh_ws")
pay.rows = 5

-- Server Settings
host = s:option(Value, "ws_host", translate("Server Host"))
host:depends("type", "ssh_ws")

ip = s:option(Value, "ws_ip", translate("Server IP"))
ip:depends("type", "ssh_ws")

port = s:option(Value, "ws_port", translate("Server Port"))
port:depends("type", "ssh_ws")
port.default = "443"

-- Credentials
user = s:option(Value, "ws_user", translate("Username"))
user:depends("type", "ssh_ws")

pass = s:option(Value, "ws_pass", translate("Password"))
pass:depends("type", "ssh_ws")
pass.password = true

-- CDN Settings
csni = s:option(Value, "ws_cdn_sni", translate("CDN SNI"))
csni:depends("type", "ssh_ws")

cip = s:option(Value, "ws_cdn_ip", translate("CDN IP"))
cip:depends("type", "ssh_ws")

cport = s:option(Value, "ws_cdn_port", translate("CDN Port"))
cport:depends("type", "ssh_ws")
cport.default = "443"

udpgw = s:option(Value, "ws_udpgw", translate("UDPGW Port"))
udpgw:depends("type", "ssh_ws")
udpgw.default = "7300"