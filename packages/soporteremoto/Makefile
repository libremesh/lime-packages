#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=soporteremoto
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) allows AlterMundi to provide remote support through SSH root access
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= +zerotier +auto-usb-wwan +kmod-ath9k-htc +ath9k-htc-firmware
endef

define Package/$(PKG_NAME)/description
  Installs auto-usb-wwan to provide a zero-configuration WWAN via USB dongle
  zerotier to provide VPN transport
  and installs a predefined set of ssh authorized_keys of AlterMundi members
  that will be granted root access
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
