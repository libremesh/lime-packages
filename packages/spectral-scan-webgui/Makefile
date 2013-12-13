#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=spectral-scan-webgui
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/spectral-scan-webgui
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Realtime spectral scanner for ath9k (web-gui)
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= +fft-eval +uhttpd +luci-lib-jquery-1-4
endef

define Package/spectral-scan-webgui/description
Simple CGI that collects ath9k spectral scan data and plots a web spectrum analyzer using jquery/flot.
endef

define Build/Compile
endef

define Package/spectral-scan-webgui/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,spectral-scan-webgui))
