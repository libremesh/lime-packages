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

include ../../libremesh.mk

PKG_VERSION:=0.0.1
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0+

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

$(eval $(call BuildPackage,$(PKG_NAME)))
