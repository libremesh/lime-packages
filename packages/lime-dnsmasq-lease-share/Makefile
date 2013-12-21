# Copyright (C) 2013 libre-mesh.org
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# The full GNU General Public License is included in this distribution in
# the file called "COPYING".
#
# Author: Gioacchino Mazzurco <gio@eigenlab.org>


include $(TOPDIR)/rules.mk

PKG_NAME:=lime-dnsmasq-lease-share
PKG_VERSION:=0.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
 SECTION:=net
 CATEGORY:=LiMe
 TITLE:=dnsmasq lease sharing accross batman-adv mesh
 URL:=http://libre-mesh.org
 DEPENDS:=+alfred +lua +libuci-lua
endef

define Package/$(PKG_NAME)/description
 Share dnsmasq lease file accross all batman-adv nodes of a mesh with enabled alfred
endef

define Build/Prepare
	@rm -rf $(PKG_BUILD_DIR) || true
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
	@cp -r ./src/. $(PKG_BUILD_DIR)/
	@sed -i '/^--!.*/d' $(PKG_BUILD_DIR)/*.lua
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_BUILD_DIR)/$(PKG_NAME).lua $(1)/usr/bin/$(PKG_NAME)
	@chmod +x $(1)/usr/bin/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
