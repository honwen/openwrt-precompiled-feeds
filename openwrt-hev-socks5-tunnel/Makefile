#
# Copyright (C) 2023-2026 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=hev-socks5-tunnel
PKG_VERSION:=2.17.1
PKG_RELEASE:=20260813
PKG_MAINTAINER:=honwen <https://github.com/honwen>

# OpenWrt ARCH: arm, aarch64, i386, x86_64, mips, mipsel
PKG_ARCH:=$(ARCH)
ifeq ($(ARCH),mips)
	PKG_ARCH:=mips32sf
endif
ifeq ($(ARCH),mipsel)
	PKG_ARCH:=mips32elsf
endif
ifeq ($(ARCH),arm)
	PKG_ARCH:=arm32v7
	ifeq ($(BOARD),bcm53xx)
		PKG_ARCH:=arm32
	endif
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
endif
ifeq ($(ARCH),i386)
	PKG_ARCH:=i686
endif

PKG_SOURCE:=$(PKG_NAME)-linux-$(PKG_ARCH)
PKG_SOURCE_URL:=https://github.com/heiher/hev-socks5-tunnel/releases/download/$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_ARCH)-$(PKG_VERSION)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	cp -Lf "$(DL_DIR)/$(PKG_SOURCE)" $(PKG_BUILD_DIR)/$(PKG_NAME)
	chmod a+x $(PKG_BUILD_DIR)/$(PKG_NAME)
endef

define Build/Compile
	echo "$(PKG_NAME)Compile Skipped!"
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=A tunnel over Socks5 proxy (tun2socks) for Linux
	URL:=https://github.com/heiher/hev-socks5-tunnel
endef

define Package/$(PKG_NAME)/description
	https://github.com/heiher/hev-socks5-tunnel
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME) $(1)/usr/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
