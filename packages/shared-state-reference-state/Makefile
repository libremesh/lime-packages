#
# Copyright (C) 2019 Gioacchino Mazzurco <gio@altermundi.net>
# Copyright (C) 2023 Javier Jorge <jjorge@inti.gob.ar>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=shared-state-wifi_links_info
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=Reference state datatypes module for shared-state
	CATEGORY:=LibreMesh
	URL:=http://libremesh.org
	DEPENDS:= shared-state 
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Syncronize Reference state datatypes using shared state multiwriter.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
