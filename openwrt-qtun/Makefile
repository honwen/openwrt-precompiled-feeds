#
# Copyright (C) 2021 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qtun
PKG_VERSION:=0.2.0
PKG_RELEASE:=20211211
PKG_MAINTAINER:=honwen <https://github.com/honwen>

PKG_SOURCE:=qtun-v$(PKG_VERSION).$(ARCH)-unknown-linux-musl.tar.xz
PKG_SOURCE_URL:=https://github.com/shadowsocks/qtun/releases/download/v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-$(ARCH)
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
	TITLE:=Yet another SIP003 plugin based on IETF-QUIC
	URL:=https://github.com/shadowsocks/qtun
endef

define Package/$(PKG_NAME)/config
	config QTUN_SERVER
		depends on PACKAGE_qtun
		bool "Build server"
endef

define Package/$(PKG_NAME)/description
	https://github.com/shadowsocks/qtun
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/qtun-client $(1)/usr/bin/
ifeq ($(CONFIG_QTUN_SERVER),y)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/qtun-server $(1)/usr/bin/
endif
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
