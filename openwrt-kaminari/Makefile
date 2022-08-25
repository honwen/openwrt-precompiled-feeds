#
# Copyright (C) 2022 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=kaminari
PKG_VERSION:=0.5.6
PKG_RELEASE:=20220726
PKG_MAINTAINER:=honwen <https://github.com/honwen>

# TODO: ARCH: mips, arm-musl

PKG_SOURCE:=$(PKG_NAME)-$(ARCH)-unknown-linux-musl.tar.gz
PKG_SOURCE_URL:=https://github.com/zephyrchien/kaminari/releases/download/v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-$(ARCH)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	tar -C $(PKG_BUILD_DIR)/ -zxf $(DL_DIR)/$(PKG_SOURCE)
endef

define Build/Compile
	echo "$(PKG_NAME) Compile Skiped!"
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Websocket tunnel / SIP003 plugin built on top of lightws.
	URL:=https://github.com/zephyrchien/kaminari
endef

define Package/$(PKG_NAME)/config
	config KAMINARI_SERVER
		depends on PACKAGE_kaminari
		bool "Build server"
endef

define Package/$(PKG_NAME)/description
	https://github.com/zephyrchien/kaminari
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kaminaric $(1)/usr/bin/
ifeq ($(CONFIG_KAMINARI_SERVER),y)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kaminaris $(1)/usr/bin/
endif
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
