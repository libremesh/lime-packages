#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=auto-usb-wwan
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) configures any USB WiFi device as WWAN upon plugging in.
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
endef

define Package/$(PKG_NAME)/description
  After installing $(PKG_NAME), a hotplug.d script will detect when any USB WiFi device is connected,
  automatically configure it to connect as client to a predefined SSID/password and ask for DHCP.
  The idea is to provide internet access to a router, without needing to mess with LuCI or CLI.
  Just insert a supported USB device on the router, and open an AP with 3g/4g tethering on a phone.
  By default, it will try connect to SSID "android" with password "internet"
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
