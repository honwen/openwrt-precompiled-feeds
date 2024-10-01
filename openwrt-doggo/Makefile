#
# Copyright (C) 2024 honwen <https://github.com/honwen>
#
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=doggo
PKG_VERSION:=2024-09-29
PKG_RELEASE:=1.0.5
PKG_MAINTAINER:=honwen <https://github.com/honwen>

PKG_ARCH:=$(ARCH)
ifeq ($(ARCH),mipsel)
	PKG_ARCH:=mipsle
endif
ifeq ($(ARCH),arm)
	PKG_ARCH:=arm6
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH:=arm64
endif

PKG_SOURCE:=$(PKG_NAME)_$(PKG_RELEASE)_Linux_$(PKG_ARCH).tar.gz
PKG_SOURCE_URL:=https://github.com/mr-karan/doggo/releases/download/v$(PKG_RELEASE)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_RELEASE)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Command-line DNS Client for Humans.
	URL:=https://github.com/mr-karan/doggo
	DEPENDS:=+ca-bundle
endef

define Package/$(PKG_NAME)/description
	doggo is a modern command-line DNS client (like dig) written in Golang. It outputs information in a neat concise manner and supports protocols like DoH, DoT, DoQ, and DNSCrypt as well.
endef

define Build/Prepare
	gzip -dc "$(DL_DIR)/$(PKG_SOURCE)" | tar -C $(PKG_BUILD_DIR)/ --strip-components 1 -xf -
endef

define Build/Compile
	echo "$(PKG_NAME) Compile Skiped!"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME) $(1)/usr/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
