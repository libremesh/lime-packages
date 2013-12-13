#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-mod-lime-basic
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Web interface for Libre-Mesh nodes
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:= +uhttpd +luci-theme-bootstrap +libiwinfo-lua +luci-mod-admin-core
endef

define Package/$(PKG_NAME)-ssl
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Web interface for Libre-Mesh nodes (SSL support)
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:= +$(PKG_NAME) +libustream-cyassl +px5g

endef

define Package/$(PKG_NAME)/description
Minimal and simple web app to configure a libre-mesh node.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

define Package/$(PKG_NAME)-ssl/install
	true
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
echo "Patching link in bootstrap no-root-password warning"
sed 's|admin/system/admin|altermesh/system/passwd|' \
  -i $${IPKG_INSTROOT}/usr/lib/lua/luci/view/themes/bootstrap/header.htm
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
echo "Reverting link in bootstrap no-root-password warning"
sed 's|altermesh/system/passwd|admin/system/admin|' \
  -i $${IPKG_INSTROOT}/usr/lib/lua/luci/view/themes/bootstrap/header.htm
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)-ssl))
