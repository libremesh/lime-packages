#
# Copyright (C) 2012 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-openairview
PKG_VERSION:=20130629
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-openairview
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=LuCI - Lua Configuration Interface
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  SUBMENU:=3. Applications
  TITLE:=Plots and tools that help visualize the spectrum and wifi neighbours
  DEPENDS:= +libc +fft-eval +luci-lib-jquery-1-4
endef

define Package/luci-app-openairview/description
Includes a realtime spectral scan for ath9k chipsets,
a realtime plot of wifi neighbours signal (think "iw station dump")
and a site survey of wifi networks, with signal plots (think "iw scan")
endef

define Build/Compile
endef

define Package/luci-app-openairview/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,luci-app-openairview))
