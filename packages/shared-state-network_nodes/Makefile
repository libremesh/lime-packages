#
# Copyright (C) 2020 German Ferrero <germanferrero@altermundi.net>
#
# This is free software, licensed under the GNU General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=$(PKG_NAME) provides shared state database of all times network nodes
  MAINTAINER:=Germán Ferrero <germanferrero@altermundi.net>
  DEPENDS:=+shared-state +shared-state-nodes_and_links +lime-system
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	This $(PKG_NAME) provides shared state database of all times network nodes.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
