#
# Copyright (C) 2013-2016 Libre-Mesh.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

LIME_BUILDDATE:=$(shell date +%Y%m%d_%H%M)
LIME_CODENAME:=biggestbang

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-freifunk
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=Freifunk metapackage using LiMe codebase
  SECTION:=lime
  CATEGORY:=LiMe
  SUBMENU:=Collections
  MAINTAINER:=Daniel Golle <daniel@makrotopia.org>
  URL:=http://libre-mesh.org
  DEPENDS:=+lime-mini
endef

define Package/$(PKG_NAME)/description
	Metapackage depending on all the required to run a freifunk/libre-mesh node
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/lime-freifunk.defaults $(1)/etc/uci-defaults/80_lime-freifunk
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
