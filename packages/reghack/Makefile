#
# Copyright (C) 2010-2013  Gioacchino Mazzurco <gio@eigenlab.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this file.  If not, see <http://www.gnu.org/licenses/>.
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
