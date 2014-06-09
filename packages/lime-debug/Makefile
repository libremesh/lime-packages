#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

LIME_BUILDDATE:=$(shell date +%Y%m%d_%H%M)
LIME_CODENAME:=bigbang

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-debug
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=libre-mesh debug utils
  CATEGORY:=LiMe
  MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
  URL:=http://libre-mesh.org
  DEPENDS:=+batctl +curl +iwinfo +iw +mtr +ip +iputils-ping6
endef

define Package/$(PKG_NAME)/description
	Debug utilities for LiMe node
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	@mkdir -p $(1)/usr/bin/ || true
	$(CP) ./src/sprunge.sh $(1)/usr/bin/sprunge
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
