# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2012-2014 Gui Iribarren

include ../../libremesh.mk

define Package/$(PKG_NAME)
  CATEGORY:=LibreMesh
  TITLE:=Set batman-adv gw_mode by internet availability
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  URL:=http://libremesh.org
  DEPENDS:= +batctl +kmod-batman-adv +watchping +dnsmasq-dhcpv6 +ip
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

$(eval $(call BuildPackage,$(PKG_NAME)))
