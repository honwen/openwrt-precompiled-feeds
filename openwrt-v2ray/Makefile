#
# Copyright (C) 2018-2020 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray
PKG_VERSION:=4.23.1
PKG_RELEASE:=20200325
PKG_MAINTAINER:=honwen <https://github.com/honwen>

# OpenWrt ARCH: arm, aarch64, i386, x86_64, mips, mipsel
# Golang ARCH: arm[5-7], arm64, 386, amd64, mips, mipsle
PKG_ARCH:=$(ARCH)
ifeq ($(ARCH),mipsel)
	PKG_ARCH:=mipsle
endif
ifeq ($(ARCH),i386)
	PKG_ARCH:=32
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=64
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
endif

PKG_SOURCE:=v2ray-linux-$(PKG_ARCH).zip
PKG_SOURCE_URL:=https://github.com/v2ray/v2ray-core/releases/download/v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/v2ray
	SECTION:=net
	CATEGORY:=Network
	TITLE:=A platform for building proxies to bypass network restrictions.
	URL:=https://github.com/v2ray/v2ray-core
endef

define Package/v2ray/description
	A platform for building proxies to bypass network restrictions.
endef

define Build/Prepare
	unzip -o -d $(PKG_BUILD_DIR)/ $(DL_DIR)/$(PKG_SOURCE)
	mv $(DL_DIR)/$(PKG_SOURCE) $(DL_DIR)/v2ray-linux-$(PKG_ARCH)-$(PKG_VERSION)-$(PKG_RELEASE).zip
endef

define Build/Compile
	echo "$(PKG_NAME)Compile Skiped!"
	[ -f $(PKG_BUILD_DIR)/v2ctl_softfloat ] && mv $(PKG_BUILD_DIR)/v2ctl_softfloat $(PKG_BUILD_DIR)/v2ctl || true
	[ -f $(PKG_BUILD_DIR)/v2ray_softfloat ] && mv $(PKG_BUILD_DIR)/v2ray_softfloat $(PKG_BUILD_DIR)/v2ray || true
	[ "V$(ARCH)" == "Varm" ] && ( [ "V$(BOARD)" == "Vbcm53xx" -o "V$(BOARD)" == "Vkirkwood" ] || mv $(PKG_BUILD_DIR)/v2ctl_armv7 $(PKG_BUILD_DIR)/v2ctl ) || true
	[ "V$(ARCH)" == "Varm" ] && ( [ "V$(BOARD)" == "Vbcm53xx" -o "V$(BOARD)" == "Vkirkwood" ] || mv $(PKG_BUILD_DIR)/v2ray_armv7 $(PKG_BUILD_DIR)/v2ray ) || true
endef

define Package/v2ray/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/v2ctl $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/v2ray $(1)/usr/bin
endef

$(eval $(call BuildPackage,v2ray))
