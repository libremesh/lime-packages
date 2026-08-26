# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2006-2014 OpenWrt.org

include ../../libremesh.mk

LIME_ID:=LibreMesh
LIME_RELEASE:=
LIME_CODENAME:=nightly
LIME_BRANCH:=$(shell git branch | sed -n '/\* /s///p')
LIME_REVISION:=r$(PKG_VERSION)
LIME_BUILD_DATE:=$(shell date +%s)

define Package/$(PKG_NAME)
  TITLE:=LibreMesh system core
  CATEGORY:=LibreMesh
  MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
  URL:=http://libremesh.org
  DEPENDS:=+firewall4 +libiwinfo-lua +lua +libuci-lua \
    +luci-lib-ip +luci-lib-nixio +luci-lib-jsonc +jq +rpcd-mod-rpcsys \
    +rpcd
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	LibreMesh is a modular meta-firmware this package provide the core of it
	which articulates all LiMe modules around it
endef

LIME_VERSION_SED:=$(SED) 's,%LIME_ID%,$(LIME_ID),g' \
	-e 's,%LIME_RELEASE%,$(LIME_RELEASE),g' \
	-e 's,%LIME_CODENAME%,$(LIME_CODENAME),g' \
	-e 's,%LIME_BRANCH%,$(LIME_BRANCH),g' \
	-e 's,%LIME_REVISION%,$(LIME_REVISION),g' \
	-e 's,%LIME_BUILD_DATE%,$(LIME_BUILD_DATE),g'

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	[ ! -d ./build/files ] || $(CP) ./build/files/* $(1)/
	$(INSTALL_DIR) $(1)/etc/hotplug.d/lime-config/
	$(INSTALL_DIR) $(1)/etc/lime-assets/community/
	$(INSTALL_DIR) $(1)/etc/lime-assets/node/

	$(LIME_VERSION_SED) $(1)/etc/lime_release
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
#[ -n "$${IPKG_INSTROOT}" ] || /etc/init.d/firewall-lime enable || true
# Add here stuff to be executed after installation at image creation time
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
