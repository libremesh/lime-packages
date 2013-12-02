#
# Copyright (C) 2013 Santiago Piccinini
#
# This is free software, licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-mod-lime-basic
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/luci-mod-lime-basic
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Web interface for Libre-Mesh nodes
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:= +uhttpd +luci-theme-bootstrap +libiwinfo-lua +luci-mod-admin-core

endef

define Package/luci-mod-lime-basic-ssl
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Web interface for Libre-Mesh nodes (SSL support)
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:= +luci-mod-lime-basic +libustream-cyassl +px5g

endef

define Package/luci-mod-lime-basic/description
Minimal and simple web app to configure a libre-mesh node.
endef

define Build/Compile
endef

define Package/luci-mod-lime-basic/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

define Package/luci-mod-lime-basic-ssl/install
	true
endef

define Package/luci-mod-lime-basic/postinst
#!/bin/sh
echo "Patching link in bootstrap no-root-password warning"
sed 's|admin/system/admin|altermesh/system/passwd|' \
  -i $${IPKG_INSTROOT}/usr/lib/lua/luci/view/themes/bootstrap/header.htm
exit 0
endef

define Package/luci-mod-lime-basic/prerm
#!/bin/sh
echo "Reverting link in bootstrap no-root-password warning"
sed 's|altermesh/system/passwd|admin/system/admin|' \
  -i $${IPKG_INSTROOT}/usr/lib/lua/luci/view/themes/bootstrap/header.htm
exit 0
endef

$(eval $(call BuildPackage,luci-mod-lime-basic))
$(eval $(call BuildPackage,luci-mod-lime-basic-ssl))
