# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2006-2013 OpenWrt.org

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) configures any USB WiFi device as WWAN upon plugging in.
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  After installing $(PKG_NAME), a hotplug.d script will detect when any USB WiFi device is connected,
  automatically configure it to connect as client to a predefined SSID/password and ask for DHCP.
  The idea is to provide internet access to a router, without needing to mess with LuCI or CLI.
  Just insert a supported USB device on the router, and open an AP with 3g/4g tethering on a phone.
  By default, it will try connect to SSID "internet" with password "internet"
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
