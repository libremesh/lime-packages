# 
# Copyright (C) 2012 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=batman-adv-auto-gw-mode
PKG_VERSION:=2.3
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/batman-adv-auto-gw-mode
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=Changes batman-adv gw_mode to reflect internet availability
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= \
	+kmod-batman-adv \
	+watchping \
	
endef

define Package/batman-adv-auto-gw-mode/description
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

define Package/batman-adv-auto-gw-mode/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,batman-adv-auto-gw-mode))
