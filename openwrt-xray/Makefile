#
# Copyright (C) 2020-2021 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=xray
PKG_VERSION:=1.4.5
PKG_RELEASE:=20210923
PKG_MAINTAINER:=honwen <https://github.com/honwen>

# OpenWrt ARCH: arm, aarch64, i386, x86_64, mips, mipsel
# Golang ARCH: arm32_v6, arm64_v8a, 32, 64, mips32, mips32le
PKG_ARCH:=$(ARCH)
ifeq ($(ARCH),mips)
	PKG_ARCH:=mips32
endif
ifeq ($(ARCH),mipsel)
	PKG_ARCH:=mips32le
endif
ifeq ($(ARCH),i386)
	PKG_ARCH:=32
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=64
endif
ifeq ($(ARCH),arm)
	PKG_ARCH:=arm32-v6
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64-v8a
endif

PKG_SOURCE:=Xray-linux-$(PKG_ARCH).zip
PKG_SOURCE_URL:=https://github.com/XTLS/Xray-core/releases/download/v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/xray
	SECTION:=net
	CATEGORY:=Network
	TITLE:=A network tool-sets originates from XTLS protocol.
	URL:=https://github.com/XTLS/Xray-core
endef

define Package/xray/config
	config XRAY_GEO_DATA
		depends on PACKAGE_xray
		bool "Build GEO Data"
endef

define Package/xray/description
	Project X originates from XTLS protocol, provides a set of network tools.
endef

define Build/Prepare
	unzip -o -d $(PKG_BUILD_DIR)/ $(DL_DIR)/$(PKG_SOURCE)
	mv $(DL_DIR)/$(PKG_SOURCE) $(DL_DIR)/xray-linux-$(PKG_ARCH)-$(PKG_VERSION)-$(PKG_RELEASE).zip
endef

define Build/Compile
	echo "$(PKG_NAME) Compile Skiped!"
	[ -f $(PKG_BUILD_DIR)/xray_softfloat ] && mv $(PKG_BUILD_DIR)/xray_softfloat $(PKG_BUILD_DIR)/xray || true
endef

define Package/xray/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/xray $(1)/usr/bin
ifeq ($(CONFIG_XRAY_GEO_DATA),y)
	$(INSTALL_DIR) $(1)/opt/share/xray
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/geosite.dat $(1)/opt/share/xray
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/geoip.dat $(1)/opt/share/xray
endif
endef

$(eval $(call BuildPackage,xray))
