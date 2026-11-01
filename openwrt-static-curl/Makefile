#
# Copyright (C) 2026 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=static-curl
PKG_VERSION:=8.23.0-1
PKG_RELEASE:=20261022
PKG_MAINTAINER:=honwen <https://github.com/honwen>

# OpenWrt ARCH: arm, aarch64, i386, x86_64, mips, mipsel, mips64, mips64el
# static-curl ARCH: armv5, armv7, aarch64, i686, x86_64, mips, mipsel, ...
PKG_ARCH:=$(ARCH)
ifeq ($(ARCH),arm)
	PKG_ARCH:=armv7
endif
ifeq ($(ARCH),i386)
	PKG_ARCH:=i686
endif

PKG_SOURCE:=curl-linux-$(PKG_ARCH)-musl-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=https://github.com/stunnel/static-curl/releases/download/$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_ARCH)-$(PKG_VERSION)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	tar -C $(PKG_BUILD_DIR)/ -Jxf $(DL_DIR)/$(PKG_SOURCE)
endef

define Build/Compile
	echo "$(PKG_NAME) Compile Skiped!"
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Static curl
	URL:=https://github.com/stunnel/static-curl
	DEPENDS:=+ca-bundle
endef

define Package/$(PKG_NAME)/description
Static curl binaries built by stunnel/static-curl, installed as s-curl.
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/curl $(1)/usr/bin/s-curl
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
