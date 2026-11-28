#
# Copyright (C) 2018-2026 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=geodata
PKG_VERSION:=202611272204
PKG_RELEASE:=20261128
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
  HASH:=9dc8e7de8db8300ce27b606f4a30632265713d2f33bcc568c0d2c44c825c8687
endef

GEOSITE_VER:=$(PKG_VERSION)
GEOSITE_FILE:=geosite.dat.$(GEOSITE_VER)
define Download/geosite
  URL:=https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/$(GEOSITE_VER)/
  URL_FILE:=geosite.dat
  FILE:=$(GEOSITE_FILE)
  HASH:=807f88fbdb144a41b3fc9fcb8a9d3fdbc45dee1e6c112a232cff91dda70f4055
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
