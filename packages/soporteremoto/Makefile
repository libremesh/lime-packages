#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) allows AlterMundi to provide remote support through SSH root access
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= +zerotier +auto-usb-wwan +kmod-ath9k-htc +ath9k-htc-firmware
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  Installs auto-usb-wwan to provide a zero-configuration WWAN via USB dongle
  zerotier to provide VPN transport
  and installs a predefined set of ssh authorized_keys of AlterMundi members
  that will be granted root access
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
