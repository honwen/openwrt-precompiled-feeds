#
# Copyright (C) 2022 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tuic-client
PKG_VERSION:=0.8.5
PKG_RELEASE:=20220730
PKG_MAINTAINER:=honwen <https://github.com/honwen>

# TODO: ARCH: mips

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(ARCH)-linux-musl
PKG_SOURCE_URL:=https://github.com/EAimTY/tuic/releases/download/$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-$(ARCH)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	cp -f $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)/$(PKG_NAME)
	chmod a+x $(PKG_BUILD_DIR)/$(PKG_NAME)
endef

define Build/Compile
	echo "$(PKG_NAME) Compile Skiped!"
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Delicately-TUICed high-performance proxy.
	URL:=https://github.com/EAimTY/tuic/
endef

define Package/$(PKG_NAME)/description
	https://github.com/EAimTY/tuic/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME) $(1)/usr/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
