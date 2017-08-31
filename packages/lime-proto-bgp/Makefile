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

PKG_NAME:=lime-proto-bgp
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=LiMe BGP proto support
  CATEGORY:=LiMe
  MAINTAINER:=Gioacchino Mazzurco <gio@diveni.re>
  URL:=http://libremesh.org
  DEPENDS:=+bird4 +bird6 +lime-system +lua
endef

define Build/Compile
	@rm -rf ./build || true
	@cp -r ./src ./build
	@sed -i '/^--!.*/d' build/*.lua
endef

define Package/$(PKG_NAME)/install
	@mkdir -p $(1)/usr/lib/lua/lime/proto || true
	$(CP) ./build/bgp.lua $(1)/usr/lib/lua/lime/proto/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

