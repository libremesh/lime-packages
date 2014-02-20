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

PKG_NAME:=lime-system
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=libre-mesh system files
  CATEGORY:=LiMe
  MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
  URL:=http://libre-mesh.org
  DEPENDS:=+lua +libuci-lua
endef

define Package/$(PKG_NAME)/description
	Basic system files for LiMe node
endef

define Package/$(PKG_NAME)/conffiles
	/etc/config/lime
	/etc/config/lime-defaults
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/lime/
	$(CP) ./files/* $(1)/
	echo "LIME_ID=LiMe" > $(1)/etc/lime/lime.release
	echo "LIME_CODENAME=$(LIME_CODENAME)" >> $(1)/etc/lime/lime.release
	echo "LIME_RELEASE=$(LIME_RELEASE)" >> $(1)/etc/lime/lime.release
	echo "LIME_BRANCH=$(BRANCH_GIT)" >> $(1)/etc/lime/lime.release
	echo "LIME_REVISION=$(REV_GIT)" >> $(1)/etc/lime/lime.release
	echo "LIME_BUILDDATE=$(LIME_BUILDDATE)" >> $(1)/etc/lime/lime.release
	echo "LIME_DESCRIPTION=\"LiMe $(LIME_CODENAME) $(LIME_RELEASE), $(BRANCH_GIT) rev.$(REV_GIT)-$(LIME_BUILDDATE)\"" >> $(1)/etc/lime/lime.release
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
