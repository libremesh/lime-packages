#
# Copyright (C) 2020 Santiago Piccinini <spiccinini@altermundi.net>
#
# This is free software, licensed under the GNU Affero General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=check-internet
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=Check internet connection
	SECTION:=utils
	CATEGORY:=Utilities
	MAINTAINER:=Santiago Piccinini <spiccinini@altermundi.net>
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Simple script to verify that there is internet access.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
