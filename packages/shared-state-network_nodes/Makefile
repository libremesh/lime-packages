#
# Copyright (C) 2020-2023 Asociacion Civil Altermundi <info@altermundi.net>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

include ../../libremesh.mk

define Package/$(PKG_NAME)
  CATEGORY:=LibreMesh
  TITLE:=$(PKG_NAME) provides data-type for user marked reliable network nodes
  MAINTAINER:=Asociacion Civil Altermundi <info@altermundi.net>
  DEPENDS:=+shared-state +shared-state-nodes_and_links +lime-system +luci-lib-jsonc \
	   +libubus-lua +random-numgen
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	TODO
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
