#
# Copyright (C) 2019 Marcos Gutierrez <gmarcos@altermundi.net>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=Pirania vaucher module for shared-state
	CATEGORY:=LibreMesh
	MAINTAINER:=Asociación Civil AlterMundi <info@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+lua +luci-lib-jsonc shared-state
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Syncronize valid pirania vauchers beween nodes
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
