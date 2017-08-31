#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

LIME_BUILDDATE:=$(shell date +%Y%m%d_%H%M)
LIME_CODENAME:=DaybootRely

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-debug
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=libremesh debug utils
	CATEGORY:=LiMe
	MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
	URL:=http://libremesh.org
	DEPENDS:=+PACKAGE_lime-proto-batadv:batctl \
		+busybox +ethtool +iwinfo +iw +mtr +ip +iputils-ping6 +iputils-ping \
		+sprunge +safe-reboot +netperf +pv +tcpdump-mini +bwm-ng
endef

define Package/$(PKG_NAME)/description
	Debug utilities for LiMe node
endef

define Package/$(PKG_NAME)/config
	select BUSYBOX_CUSTOM
	select BUSYBOX_CONFIG_NC
	select BUSYBOX_CONFIG_NC_SERVER
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
