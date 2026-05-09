m = Map("qtun", translate("QTUN - Routing Strategy"))

s = m:section(NamedSection, "main", "global", translate("Traffic Rules"))

-- Mode Clash: Rule, Global, atau Direct
mode = s:option(ListValue, "clash_mode", translate("Mihomo Mode"))
mode:value("rule", "Rule (Smart Routing)")
mode:value("global", "Global (All Tunnel)")
mode:value("direct", "Direct (No Tunnel)")

-- Enhanced Features
s:option(Flag, "udp", translate("UDP Support"), translate("Aktifkan untuk gaming"))
s:option(Flag, "ipv6", translate("IPv6 Support"))

-- DNS Settings (Clash DNS)
dns = s:option(Flag, "enhanced_dns", translate("Enable Fake-IP"), translate("Mempercepat koneksi dengan sistem caching Clash"))

return m