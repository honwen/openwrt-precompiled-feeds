#
# Copyright (C) 2022-2023 honwen <https://github.com/honwen>
#
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dnslookup
PKG_VERSION:=2023-03-22
PKG_RELEASE:=1.9.1
PKG_MAINTAINER:=honwen <https://github.com/honwen>

# OpenWrt ARCH: arm, aarch64, i386, x86_64, mips, mipsel
# Golang ARCH: arm6, arm64, 386, amd64, mips, mipsle
PKG_ARCH:=$(ARCH)
ifeq ($(ARCH),mipsel)
	PKG_ARCH:=mipsle
endif
ifeq ($(ARCH),i386)
	PKG_ARCH:=386
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=amd64
endif
ifeq ($(ARCH),arm)
	PKG_ARCH:=arm6
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
endif

PKG_SOURCE:=$(PKG_NAME)-linux-$(PKG_ARCH)-v$(PKG_RELEASE).tar.gz
PKG_SOURCE_URL:=https://github.com/ameshkov/dnslookup/releases/download/v$(PKG_RELEASE)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_RELEASE)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Simple command line utility to make DNS lookups.
	URL:=https://github.com/ameshkov/dnslookup
	DEPENDS:=+ca-bundle
endef

define Package/$(PKG_NAME)/description
	Simple command line utility to make DNS lookups. Supports all known DNS protocols: plain DNS, DoH, DoT, DoQ, DNSCrypt.
endef

define Build/Prepare
	gzip -dc "$(DL_DIR)/$(PKG_SOURCE)" | tar -C $(PKG_BUILD_DIR)/ -xf -
endef

define Build/Compile
	echo "$(PKG_NAME) Compile Skiped!"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linux-$(PKG_ARCH)/dnslookup $(1)/usr/bin/dnslookup
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
