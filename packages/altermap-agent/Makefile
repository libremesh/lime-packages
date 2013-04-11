#
# Copyright (C) 2012 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=altermap-agent
PKG_VERSION:=$(shell hg log --template "{date|shortdate}-{rev}\n" -l 1 .)
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/altermap-agent
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Send system information to an AlterMap server
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= +curl +jshn +sysinfo-json
endef

define Package/altermap-agent/description
Small script that collects info (network settings, wifi stations, etc) from a router, and sends it to a map server.
endef

define Build/Compile
endef

define Package/altermap-agent/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,altermap-agent))
