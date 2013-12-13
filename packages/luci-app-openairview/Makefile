#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-openairview
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-openairview
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=LuCI - Lua Configuration Interface
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  SUBMENU:=3. Applications
  TITLE:=Plots and tools that help visualize the spectrum and wifi neighbours
  DEPENDS:= +libc +fft-eval +luci-lib-jquery-1-4 +luci-lib-json
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
