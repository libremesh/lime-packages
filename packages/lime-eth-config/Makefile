#
# Copyright (C) 2025 Javier Jorge <jjorge@inti.gob.ar>
# Copyright (c) 2025  Instituto Nacional de Tecnología Industrial
# Copyright (C) 2025  Asociación Civil Altermundi <info@altermundi.net>
# This is free software, licensed under the GNU Affero General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-eth-config
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=Ethernet configuration for LibreMesh Lime-App
	CATEGORY:=LibreMesh
	MAINTAINER:=Asociación Civil Altermundi <info@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+libubus-lua +lime-system +lua +luci-lib-jsonc 
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Ethernet port configuration for LibreMesh Lime-App.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
