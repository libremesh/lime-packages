#
# Copyright (C) 2023 Javier Jorge <jjorge@inti.gob.ar>
# Copyright (C) 2023  Asociación Civil Altermundi <info@altermundi.net>
# This is free software, licensed under the GNU Affero General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=shared-state-node_info
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=Node information module for shared-state
	CATEGORY:=LibreMesh
	MAINTAINER:= Javier <jjorge@inti.gob.ar>
	URL:=http://libremesh.org
	DEPENDS:=+lua +luci-lib-jsonc +ubus-lime-utils \
		+lime-system +ubus-lime-location shared-state 
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Syncronize node information beween nodes.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
