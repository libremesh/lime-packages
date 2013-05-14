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

PKG_NAME:=altermesh-webgui
PKG_VERSION:=$(shell hg log --template "{date|shortdate}-{rev}\n" -l 1 .)
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/altermesh-webgui
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:==Web interface for AlterMesh nodes
  MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
  DEPENDS:= +uhttpd +luci-theme-bootstrap +libiwinfo-lua +luci-mod-admin-core

endef

define Package/altermesh-webgui/description
Minimal and simple web app to configure an altermesh node.
endef

define Build/Compile
endef

define Package/altermesh-webgui/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

define Package/altermesh-webgui/postinst
#!/bin/sh
echo "Patching link in bootstrap no-root-password warning"
sed 's|admin/system/admin|altermesh/system/passwd|' \
  -i $${IPKG_INSTROOT}/usr/lib/lua/luci/view/themes/bootstrap/header.htm
exit 0
endef

define Package/altermesh-webgui/prerm
#!/bin/sh
echo "Reverting link in bootstrap no-root-password warning"
sed 's|altermesh/system/passwd|admin/system/admin|' \
  -i $${IPKG_INSTROOT}/usr/lib/lua/luci/view/themes/bootstrap/header.htm
exit 0
endef

$(eval $(call BuildPackage,altermesh-webgui))
