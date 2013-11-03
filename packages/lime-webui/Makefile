#   Copyright (C) 2013 libre-mesh.org
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#    The full GNU General Public License is included in this distribution in
#    the file called "COPYING".
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=lime-webui
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
LIME_CODENAME:=bigbang

include $(INCLUDE_DIR)/package.mk

define Package/lime-webui
  TITLE:=libre-mesh web user interface based on LUCI
  SECTION:=net
  CATEGORY:=LiMe
  URL:=http://libre-mesh.org
  DEPENDS:=+luci +luci-app-bmx6 +luci-app-batman-adv
endef

define Package/lime-webui/description
	Web interface for Libre-Mesh
endef

define Build/Configure
endef

define Build/Compile
	@rm -rf ./build || true
	@cp -r ./src ./build
	@sed -i '/^--!.*/d' ./build/*.lua
endef

define Package/lime-webui/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/lime
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/lime
	$(INSTALL_DIR) $(1)/www/luci-static/resources/lime
	$(CP) ./build/model/* $(1)/usr/lib/lua/luci/model/cbi/lime/
	$(CP) ./build/controller/* $(1)/usr/lib/lua/luci/controller/
	$(CP) ./build/view/* $(1)/usr/lib/lua/luci/view/lime/
	$(CP) ./build/static/* $(1)/www/luci-static/resources/lime/
endef

$(eval $(call BuildPackage,lime-webui))
