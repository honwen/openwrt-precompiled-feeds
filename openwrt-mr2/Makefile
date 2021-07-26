#
# Copyright (C) 2019-2021 honwen <https://github.com/honwen>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mr2
PKG_VERSION:=0.0.5
PKG_RELEASE:=20210401
PKG_MAINTAINER:=honwen <https://github.com/honwen>

# OpenWrt ARCH: arm, i386, x86_64, mips, mipsel
# Golang ARCH: arm[5-7], 386, amd64, mips, mipsle
PKG_ARCH:=$(ARCH)
ifeq ($(ARCH),mips)
	PKG_ARCH:=_linux_mips
endif
ifeq ($(ARCH),mipsel)
	PKG_ARCH:=_linux_mipsle
endif
ifeq ($(ARCH),arm)
	PKG_ARCH:=_linux_arm6
	ifneq ($(BOARD),bcm53xx)
		PKG_ARCH:=_linux_arm7
	endif
endif
ifeq ($(ARCH),i386)
	PKG_ARCH:=_linux_386
endif
ifeq ($(ARCH),x86_64)
	PKG_ARCH:=_linux_amd64
endif

PKG_SOURCE:=mr2$(PKG_ARCH)
PKG_SOURCE_URL:=https://github.com/txthinking/mr2/releases/download/v$(PKG_RELEASE)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_RELEASE)
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/mr2
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Expose local server to external network
	URL:=https://github.com/txthinking/mr2
endef

define Package/mr2/description
	https://github.com/txthinking/mr2
endef

define Build/Prepare
	cp -f $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)/
	mv $(DL_DIR)/$(PKG_SOURCE) $(DL_DIR)/mr2$(PKG_ARCH)-$(PKG_RELEASE)-$(PKG_RELEASE)
endef

define Build/Compile
    echo "$(PKG_NAME) Compile Skiped!"
endef

define Package/mr2/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/mr2$(PKG_ARCH) $(1)/usr/bin/mr2
endef

$(eval $(call BuildPackage,mr2))
