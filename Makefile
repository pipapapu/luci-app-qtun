include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-qtun
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_BUILD_PARALLEL:=1
PKG_FLAGS:=nonshared

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Azy <azyanggara2707@gmail.com>

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/luci/luci.mk


define Package/luci-app-qtun
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI interface for Q-Tunneling
  URL:=https://github.com/QcomWrt/luci-app-qtun
  DEPENDS:=+luci-base +bash +curl +ca-bundle +ca-certificates +gunzip +jq
endef

define Package/luci-app-qtun/description
 LuCI interface for Q-Tunneling with ZiVPN, Clash (Mihomo),
 SSH, SSH-WS, SSH-SSL and Q-Load core support.
endef


MIHOMO_VER:=v1.19.9
QLOAD_VER:=v1.0.0
ZIVPN_VER:=udp-zivpn_1.4.9


MIHOMO_URL:=https://github.com/MetaCubeX/Mihomo/releases/download/$(MIHOMO_VER)
QLOAD_URL:=https://github.com/QcomWrt/Q-load/releases/download/$(QLOAD_VER)
ZIVPN_URL:=https://github.com/zahidbd2/udp-zivpn/releases/download/$(ZIVPN_VER)


ifeq ($(ARCH),x86_64)
  M_ARCH:=amd64
  Q_ARCH:=amd64
  Z_ARCH:=amd64
else ifeq ($(ARCH),aarch64)
  M_ARCH:=arm64
  Q_ARCH:=arm64
  Z_ARCH:=arm64
else ifeq ($(ARCH),arm)
  M_ARCH:=armv7
  Q_ARCH:=armv7
  Z_ARCH:=arm
else
  $(error Unsupported ARCH: $(ARCH))
endif


define Build/Prepare
	$(call Build/Prepare/Default)

	mkdir -p $(PKG_BUILD_DIR)/cores

	curl -fL $(MIHOMO_URL)/mihomo-linux-$(M_ARCH)-$(MIHOMO_VER).gz \
		-o $(PKG_BUILD_DIR)/cores/clash.gz
	gunzip -f $(PKG_BUILD_DIR)/cores/clash.gz

	curl -fL $(QLOAD_URL)/q-load-linux-$(Q_ARCH) \
		-o $(PKG_BUILD_DIR)/cores/q-load

	curl -fL $(ZIVPN_URL)/udp-zivpn-linux-$(Z_ARCH) \
		-o $(PKG_BUILD_DIR)/cores/zivpn

	chmod +x $(PKG_BUILD_DIR)/cores/clash
	chmod +x $(PKG_BUILD_DIR)/cores/q-load
	chmod +x $(PKG_BUILD_DIR)/cores/zivpn
endef


define Build/Compile
	true
endef


define Package/luci-app-qtun/install


	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./etc/config/qtun $(1)/etc/config/qtun


	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./etc/init.d/qtun_autoboot \
		$(1)/etc/init.d/qtun_autoboot


	$(INSTALL_DIR) $(1)/etc/qtun
	$(INSTALL_DIR) $(1)/etc/qtun/action
	$(INSTALL_DIR) $(1)/etc/qtun/config
	$(INSTALL_DIR) $(1)/etc/qtun/config/clash
	$(INSTALL_DIR) $(1)/etc/qtun/config/zivpn
	$(INSTALL_DIR) $(1)/etc/qtun/core
	$(INSTALL_DIR) $(1)/etc/qtun/run


	$(INSTALL_BIN) ./etc/qtun/action/*.sh \
		$(1)/etc/qtun/action/

	$(INSTALL_CONF) ./etc/qtun/config/clash/zivpn.yaml \
		$(1)/etc/qtun/config/clash/zivpn.yaml

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/cores/clash \
		$(1)/etc/qtun/core/clash

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/cores/q-load \
		$(1)/etc/qtun/core/q-load

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/cores/zivpn \
		$(1)/etc/qtun/core/zivpn

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) ./usr/lib/lua/luci/* \
		$(1)/usr/lib/lua/luci/

endef


$(eval $(call BuildPackage,luci-app-qtun))
