#
# Copyright (C) 2020 Gui iribarren <gui@altermundi.net>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=shared-state-dnsmasq_servers
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=Mesh DNS module for shared-state
	CATEGORY:=LiMe
	MAINTAINER:=Gui iribarren <gui@altermundi.net>
	URL:=http://libremesh.org
	DEPENDS:=+@BUSYBOX_CONFIG_ASH_RANDOM_SUPPORT +lua +luci-lib-jsonc \
		shared-state
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Generates 'server' lines in dnsmasq config, so that domain zones published
	by other nodes in the mesh can be resolved transparently.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
