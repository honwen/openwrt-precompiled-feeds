#
# Copyright (C) 2021 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=xray-plugin
PKG_VERSION:=1.4.2
PKG_RELEASE:=20210401
PKG_MAINTAINER:=chenhw2 <https://github.com/chenhw2>

# OpenWrt ARCH: arm, i386, x86_64, mips, mipsel
# Golang ARCH: arm[5-7], 386, amd64, mips, mipsle
PKG_ARCH:=$(ARCH)
BIN_ARCH:=$(ARCH)
ifeq ($(ARCH),mips)
	BIN_ARCH:=mips_sf
endif
ifeq ($(ARCH),mipsel)
	PKG_ARCH:=mips
	BIN_ARCH:=mipsle_sf
endif
ifeq ($(ARCH),i386)
	PKG_ARCH:=386
	BIN_ARCH:=386
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=amd64
	BIN_ARCH:=amd64
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
	BIN_ARCH:=arm64
endif
ifeq ($(ARCH),arm)
	BIN_ARCH:=arm7
endif

PKG_SOURCE:=$(PKG_NAME)-linux-$(PKG_ARCH)-v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/teddysun/$(PKG_NAME)/releases/download/v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=SIP003 plugin for shadowsocks, based on Xray
	URL:=https://github.com/teddysun/xray-plugin
endef

define Package/$(PKG_NAME)/description
	Yet another SIP003 plugin for shadowsocks, based on Xray-core
endef

define Build/Prepare
	gzip -dc "$(DL_DIR)/$(PKG_SOURCE)" | tar -C $(PKG_BUILD_DIR)/ -xf -
endef

define Build/Compile
	echo "$(PKG_NAME)Compile Skipped!"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME)_linux_$(BIN_ARCH) $(1)/usr/bin/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

