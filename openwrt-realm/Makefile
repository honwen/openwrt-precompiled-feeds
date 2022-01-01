#
# Copyright (C) 2021 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=realm
PKG_VERSION:=2.0.4
PKG_RELEASE:=20220101

# refer: https://github.com/honwen/openwrt-realm/commit/1c42f16ba56440bffd3560aa5d1c8305f5d9e1c5
PKG_LIBC:=musl
ifeq ($(ARCH),arm)
  PKG_LIBC:=musleabi

  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifneq ($(filter $(ARM_CPU_FEATURES),vfp vfpv2),)
    PKG_LIBC:=musleabihf
  endif
endif

PKG_SOURCE:=realm-v$(PKG_VERSION).$(ARCH)-unknown-linux-$(PKG_LIBC).tar.gz
PKG_SOURCE_URL:=https://github.com/honwen/realm/releases/download/v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=High performance relay server - Rust.
	URL:=https://github.com/honwen/realm
endef

define Package/$(PKG_NAME)/description
This is a simple, high performance relay server.
endef

define Build/Prepare
	tar -C $(PKG_BUILD_DIR)/ -zxf $(DL_DIR)/$(PKG_SOURCE)
endef

define Build/Compile
	echo "$(PKG_NAME) Compile Skiped!"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/realm $(1)/usr/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
