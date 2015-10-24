#
# Copyright (C) 2006-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=libluciip-lua
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=LuCI IP calculation library
	SECTION:=libs
	CATEGORY:=Libraries
	MAINTAINER:=Ilario Gelmetti <ilario@eigenlab.org>
	URL:=http://libre-mesh.org
	DEPENDS:= +lua +luci-lib-nixio +luci-base
endef

define Package/$(PKG_NAME)/description
	IP calculation library from LuCI 0.12
	Original version can be found on
	http://git.openwrt.org/?p=project/luci.git;a=blob;f=modules/base/luasrc/ip.lua;hb=refs/heads/luci-0.12
endef

define Build/Prepare
        mkdir -p $(1)/usr/lib/lua
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
