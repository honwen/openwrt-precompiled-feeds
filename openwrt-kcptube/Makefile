#
# Copyright (C) 2023-2024 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=kcptube
PKG_VERSION:=0.7.0
PKG_RELEASE:=20241201
PKG_MAINTAINER:=honwen <https://github.com/honwen>

PKG_ARCH:=$(ARCH)
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=x64
endif

PKG_SOURCE:=$(PKG_NAME)-linux-musl-$(PKG_ARCH).tar.bz2
PKG_SOURCE_URL:=https://github.com/cnbatch/kcptube/releases/download/v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE)-$(ARCH)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	tar -C $(PKG_BUILD_DIR)/ -jxf $(DL_DIR)/$(PKG_SOURCE)
	mv $(DL_DIR)/$(PKG_SOURCE) $(DL_DIR)/$(PKG_NAME)-linux-musl-$(PKG_VERSION)-$(PKG_RELEASE)-$(PKG_ARCH).tar.gz
endef

define Build/Compile
	echo "$(PKG_NAME) Compile Skiped!"
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=A tool of TCP/UDP's Port Hopping
	URL:=https://github.com/cnbatch/kcptube
endef

define Package/$(PKG_NAME)/description
	https://github.com/cnbatch/kcptube
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kcptube $(1)/usr/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
