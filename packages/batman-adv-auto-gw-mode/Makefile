# 
# Copyright (C) 2012-2014 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=batman-adv-auto-gw-mode
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=LiMe
  TITLE:=Set batman-adv gw_mode by internet availability
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  URL:=http://libremesh.org
  DEPENDS:= +kmod-batman-adv +watchping +odhcpd-ipv6only +ip
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
Adds watchping hooks that set 
gw_mode=server when WAN port gets internet access
gw_mode=client when connection is severed

Also adds a hotplug.d hook that sends a DHCP request
when another batman-adv router announces itself
as a gw_mode=server.

So if you install this package on every node of a batman-adv
mesh network, you can connect internet access to the WAN
port of any (one or more) nodes, it will be autodetected
and the rest of the nodes will route through it (or them)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
