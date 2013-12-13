#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=reghack
PKG_VERSION:=20130625
PKG_RELEASE=$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

LIBRE_MESH_NAME:=Libre Mesh
LIBRE_MESH_PREFIX:=lime

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/template
	SECTION:=admin
	CATEGORY:=Administration
	MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
	SUBMENU:=$(LIBRE_MESH_NAME)
endef

define Package/$(PKG_NAME)
	$(call Package/$(PKG_NAME)/template)
	TITLE:=Regulatory domain unlocker
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(call Build/Prepare/Default)
endef

define Build/Compile
	$(TARGET_CC) -o $(PKG_BUILD_DIR)/reghack $(PKG_BUILD_DIR)/reghack.c
	$(HOSTCC) -o $(STAGING_DIR_HOST)/bin/reghack $(PKG_BUILD_DIR)/reghack.c
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/reghack $(1)/usr/bin/reghack
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
for module in ath cfg80211 ; do
	cp "$$IPKG_INSTROOT"/lib/modules/*/$${module}.ko /tmp/
	reghack /tmp/$${module}.ko && \
	mv /tmp/$${module}.ko "$$IPKG_INSTROOT"/lib/modules/*/
done
endef
$(eval $(call BuildPackage,$(PKG_NAME)))
