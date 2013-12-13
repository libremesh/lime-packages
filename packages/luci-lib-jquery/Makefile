#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-lib-jquery
PKG_VERSION:=1.4
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-lib-jquery-1-4
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=LuCI - Lua Configuration Interface
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  SUBMENU:=8. Libraries
  TITLE:=jQuery library
endef

define Package/luci-lib-jquery-1-4/description
endef

define Build/Compile
endef

define Package/luci-lib-jquery-1-4/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/jquery/
	$(CP) ./files/* $(1)/www/luci-static/resources/jquery/
endef

$(eval $(call BuildPackage,luci-lib-jquery-1-4))
