#
# Copyright (C) 2012 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-batman-adv
PKG_VERSION:=20130629
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-batman-adv
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=LuCI - Lua Configuration Interface
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  SUBMENU:=3. Applications
  TITLE:=B.A.T.M.A.N.-Adv configuration and status module
  DEPENDS:= +libc +kmod-batman-adv
endef

define Package/luci-app-batman-adv/description
endef

define Build/Compile
endef

define Package/luci-app-batman-adv/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,luci-app-batman-adv))
