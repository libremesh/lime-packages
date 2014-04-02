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

PKG_NAME:=lime-full
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=libre-mesh metapackage
  CATEGORY:=LiMe
  MAINTAINER:=Pau Escrich <p4u@dabax.net>
  URL:=http://libre-mesh.org
  DEPENDS:=+lime-system +lime-proto-bmx6 +lime-proto-batadv +lime-proto-anygw +dnsmasq-lease-share \
		+libremap-agent +luci-lib-libremap-contact +luci-lib-libremap-location +luci-lib-libremap-system \
		+lime-webui +luci-app-batman-adv +luci-app-bmx6 \
		+reghack \
		+lime-debug
endef

define Package/$(PKG_NAME)/description
	Addons required to run a full libre-mesh node
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/lime/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
