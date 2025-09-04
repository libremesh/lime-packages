# SPDX-License-Identifier: AGPL-3.0-only
#
# Copyright (C) 2020 Gui iribarren <gui@altermundi.net>

include ../../libremesh.mk

define Package/$(PKG_NAME)
	TITLE:=Mesh DNS module for shared-state
	CATEGORY:=LibreMesh
	MAINTAINER:=Gui iribarren <gui@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+lua +luci-lib-jsonc \
		shared-state
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Generates 'server' lines in dnsmasq config, so that domain zones published
	by other nodes in the mesh can be resolved transparently.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
