#
# Copyright (C) 2012 Gui Iribarren
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=altermesh-webgui
PKG_VERSION:=1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/altermesh-webgui
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Web interface for AlterMesh nodes
  MAINTAINER:=Gui Iribarren <gui@altermundi.net>
  DEPENDS:= +uhttpd
endef

define Package/altermesh-webgui/description
Allows user to set hostname, and displays an external mapping application.
endef

define Build/Compile
endef

define Package/altermesh-webgui/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,altermesh-webgui))
