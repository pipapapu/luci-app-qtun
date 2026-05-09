m = Map("qtun", translate("QTUN - Advanced Tools"))

-- Global Settings
g = m:section(NamedSection, "main", "global", translate("System Ports"))

-- Port untuk SSH Local Proxy
ssh_p = g:option(Value, "ssh_local_port", translate("SSH Local SOCKS5 Port"))
ssh_p.default = "1080"
ssh_p.datatype = "port"

-- Port untuk Mihomo Mixed Port
mih_p = g:option(Value, "mihomo_port", translate("Mihomo Mixed Port"))
mih_p.default = "7890"
mih_p.datatype = "port"

-- Auto Reconnect
g:option(Flag, "auto_recon", translate("Auto Reconnect"), translate("Cek koneksi SSH/Mihomo secara berkala"))

return m