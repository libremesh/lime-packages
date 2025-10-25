# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2019 Marcos Gutierrez <gmarcos@altermundi.net>

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
