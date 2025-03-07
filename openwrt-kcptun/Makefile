#
# Copyright (C) 2021-2024 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=kcptun
PKG_VERSION:=1.3.0
PKG_RELEASE:=20241227
PKG_MAINTAINER:=honwen <https://github.com/honwen>

# OpenWrt ARCH: arm, aarch64, i386, x86_64, mips, mipsel
# Golang ARCH: arm[5-7], arm64, 386, amd64, mips, mipsle
PKG_ARCH:=$(ARCH)
ifeq ($(ARCH),mipsel)
	PKG_ARCH:=mipsle
endif
ifeq ($(ARCH),arm)
	PKG_ARCH:=arm6
	ifneq ($(BOARD),bcm53xx)
		PKG_ARCH:=arm7
	endif
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm84
endif
ifeq ($(ARCH),i386)
	PKG_ARCH:=386
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=amd64
endif

PKG_SOURCE:=kcptun-linux-$(PKG_ARCH)-$(PKG_RELEASE).tar.gz
PKG_SOURCE_URL:=https://github.com/xtaci/kcptun/releases/download/v$(PKG_RELEASE)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_RELEASE)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	tar -C $(PKG_BUILD_DIR)/ -xzf "$(DL_DIR)/$(PKG_SOURCE)"
	mv $(PKG_BUILD_DIR)/client_* $(PKG_BUILD_DIR)/kcpc
	mv $(PKG_BUILD_DIR)/server_* $(PKG_BUILD_DIR)/kcps
endef

define Build/Compile
	echo "$(PKG_NAME) Compile Skiped!"
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=A Stable & Secure Tunnel based on KCP
	URL:=https://github.com/xtaci/kcptun
endef

define Package/$(PKG_NAME)/config
	config KCPTUN_SERVER
		depends on PACKAGE_kcptun
		bool "Build server"
endef

define Package/$(PKG_NAME)/description
	https://github.com/xtaci/kcptun
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kcpc $(1)/usr/bin/
ifeq ($(CONFIG_KCPTUN_SERVER),y)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kcps $(1)/usr/bin/
endif
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
