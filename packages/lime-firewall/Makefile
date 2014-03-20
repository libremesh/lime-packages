#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lime-firewall
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
 SECTION:=net
 CATEGORY:=LiMe
 TITLE:=LiMe lite firewall
 MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
 URL:=http://libre-mesh.org
 DEPENDS:=+iptables +ebtables @(!PACKAGE_firewall)
endef

define Package/$(PKG_NAME)/description
 Very simple modular firewall to permit easy and understendable configurations
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
