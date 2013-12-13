#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-lib-jquery-1-4
PKG_VERSION:=1.4
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=LuCI - Lua Configuration Interface
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  SUBMENU:=8. Libraries
  TITLE:=jQuery library
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/jquery/
	$(CP) ./files/* $(1)/www/luci-static/resources/jquery/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
