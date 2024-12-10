#
# Copyright (C) 2018-2024 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray
PKG_VERSION:=5.23.0
PKG_RELEASE:=20241210
PKG_MAINTAINER:=honwen <https://github.com/honwen>

# OpenWrt ARCH: arm, aarch64, i386, x86_64, mips, mipsel
# Golang ARCH: arm32, arm64, 386, amd64, mips32, mips32le
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
	PKG_ARCH:=arm32-v7a
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64-v8a
endif

PKG_SOURCE:=v2ray-linux-$(PKG_ARCH).zip
PKG_SOURCE_URL:=https://github.com/v2fly/v2ray-core/releases/download/v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=A platform for building proxies to bypass network restrictions.
	URL:=https://github.com/v2fly/v2ray-core
endef

define Package/$(PKG_NAME)/description
	A platform for building proxies to bypass network restrictions.
endef

define Build/Prepare
	unzip -o -d $(PKG_BUILD_DIR)/ $(DL_DIR)/$(PKG_SOURCE)
	mv $(DL_DIR)/$(PKG_SOURCE) $(DL_DIR)/v2ray-linux-$(PKG_ARCH)-$(PKG_VERSION)-$(PKG_RELEASE).zip
endef

define Build/Compile
	echo "$(PKG_NAME) Compile Skiped!"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/v2ray $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
