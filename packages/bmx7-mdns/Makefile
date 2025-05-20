#    Copyright (C) 2018 Pau Escrich
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
# Contributors:
#	Pau Escrich <p4u@dabax.net>
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=bmx7-mdns
PKG_VERSION:=0.1
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0+
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=bmx7 distributed DNS system
  URL:=http://bmx6.net
  MAINTAINER:=Pau Escrich <p4u@dabax.net>
  PKGARCH:=all
  DEPENDS:=+bmx7 +bmx7-sms +luci-lib-nixio
endef

define Package/$(PKG_NAME)/config
  select CONFIG_BUSYBOX_CONFIG_CROND
  select CONFIG_BUSYBOX_CONFIG_CRONTAB
endef

define Package/$(PKG_NAME)/description
 Distributed DNS system using bmx7 sms plugin
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(CP) ./files/etc/init.d/bmx7-mdns $(1)/etc/init.d/bmx7-mdns
	chmod 755 $(1)/etc/init.d/bmx7-mdns
	$(CP) ./files/etc/config/bmx7-mdns $(1)/etc/config/bmx7-mdns
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/
	$(CP) ./files/luci/bmx7-mdns.lua $(1)/usr/lib/lua/luci/model/cbi/bmx7-mdns.lua
endef

$(eval $(call BuildPackage,bmx7-mdns))
