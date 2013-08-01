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
PKG_RELEASE:=1

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

define Package/$(PKG_NAME)/install
	@mkdir -p $(1)/usr/bin
	$(CP) build/reghack $(1)/usr/bin/reghack
	@chmod +x $(1)/usr/bin/reghack
	@mkdir -p $(1)/etc/uci-defaults
	$(CP) src/reghack.sh $(1)/etc/uci-defaults/reghack.sh
	@chmod +x $(1)/etc/uci-defaults/reghack.sh
endef

define Build/Compile
	@mkdir -p ./build || true
	$(TARGET_CC) src/reghack.c -o build/reghack
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
