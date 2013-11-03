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

PKG_NAME:=lime-system
PKG_RELEASE:=12
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
LIME_BUILDDATE:=$(shell date +%Y%m%d_%H%M)
LIME_CODENAME:=bigbang

include $(INCLUDE_DIR)/package.mk

define Package/lime-system
  TITLE:=libre-mesh system files
  SECTION:=net
  CATEGORY:=LiMe
  URL:=http://libre-mesh.org
  DEPENDS:=+lime-webui \
  +iwinfo +iw +netperf +mtr +lime-dnsmasq-lease-share \
  +bmx6 +bmx6-uci-config +bmx6-json +bmx6-sms +bmx6-table \
  +kmod-batman-adv \
  +wpad-mini +reghack \
  +kmod-macvlan +ebtables \
  +dhcpdiscover +ip +iputils-ping6 \
  +lime-dnsmasq-lease-share
endef

define Package/lime-system/description
	Basic system files for LiMe node
endef

define Package/lime-system/conffiles
	/etc/config/lime
	/etc/config/lime-defaults
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/lime-system/install
	$(INSTALL_DIR) $(1)/etc/lime/
	$(CP) ./files/* $(1)/
	echo "LIME_ID=LiMe" > $(1)/etc/lime/lime.release
	echo "LIME_CODENAME=$(LIME_CODENAME)" >> $(1)/etc/lime/lime.release
	echo "LIME_RELEASE=$(LIME_RELEASE)" >> $(1)/etc/lime/lime.release
	echo "LIME_BRANCH=$(BRANCH_GIT)" >> $(1)/etc/lime/lime.release
	echo "LIME_REVISION=$(REV_GIT)" >> $(1)/etc/lime/lime.release
	echo "LIME_BUILDDATE=$(LIME_BUILDDATE)" >> $(1)/etc/lime/lime.release
	echo "LIME_DESCRIPTION=\"LiMe $(LIME_CODENAME) $(LIME_RELEASE), $(BRANCH_GIT) rev.$(REV_GIT)-$(LIME_BUILDDATE)\"" >> $(1)/etc/lime/lime.release
endef

$(eval $(call BuildPackage,lime-system))
