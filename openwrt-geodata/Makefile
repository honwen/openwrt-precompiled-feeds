#
# Copyright (C) 2018-2026 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=geodata
PKG_VERSION:=202610092207
PKG_RELEASE:=20261010
PKG_MAINTAINER:=honwen <https://github.com/honwen>

PKG_LICENSE:=CC-BY-SA-4.0 MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

# 数据来自 Loyalsoldier/v2ray-rules-dat（geoip.dat + geosite.dat）
GEOIP_VER:=$(PKG_VERSION)
GEOIP_FILE:=geoip.dat.$(GEOIP_VER)
define Download/geoip
  URL:=https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/$(GEOIP_VER)/
  URL_FILE:=geoip.dat
  FILE:=$(GEOIP_FILE)
  HASH:=116cc0f03d48991962f7f9cdbbcf53d45d89777f9c3cd1a663210853e5df6093
endef

GEOSITE_VER:=$(PKG_VERSION)
GEOSITE_FILE:=geosite.dat.$(GEOSITE_VER)
define Download/geosite
  URL:=https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/$(GEOSITE_VER)/
  URL_FILE:=geosite.dat
  FILE:=$(GEOSITE_FILE)
  HASH:=79d15a5bd8205d83c377fcfde394500db762b2b400feff24612834e528a111cb
endef

define Package/geodata
	SECTION:=net
	CATEGORY:=Network
	TITLE:=GeoIP and GeoSite data files (Loyalsoldier)
	URL:=https://github.com/Loyalsoldier/v2ray-rules-dat
	PKGARCH:=all
	PROVIDES:=xray-geodata xray-geoip xray-geosite
endef

define Package/geodata/description
 GeoIP (geoip.dat) and GeoSite (geosite.dat) data files maintained by
 Loyalsoldier. Installed to /usr/share/xray for Xray, with symlinks in
 /usr/share/v2ray for V2Ray.
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	$(call Download,geoip)
	$(call Download,geosite)
endef

define Build/Compile
endef

define Package/geodata/install
	$(INSTALL_DIR) $(1)/usr/share/xray $(1)/usr/share/v2ray
	$(INSTALL_DATA) $(DL_DIR)/$(GEOIP_FILE) $(1)/usr/share/xray/geoip.dat
	$(INSTALL_DATA) $(DL_DIR)/$(GEOSITE_FILE) $(1)/usr/share/xray/geosite.dat
	$(LN) ../xray/geoip.dat $(1)/usr/share/v2ray/geoip.dat
	$(LN) ../xray/geosite.dat $(1)/usr/share/v2ray/geosite.dat
endef

$(eval $(call BuildPackage,geodata))
