# 
# Copyright (C) 2019 Ilario Gelmetti
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=bandwidth-test
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=LibreMesh
  TITLE:=Internet download bandwidth measurement
  MAINTAINER:=Ilario Gelmetti <iochesonome@gmail.com>
  URL:=https://libremesh.org
  DEPENDS:=+pv
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/config
endef


define Package/$(PKG_NAME)/description
  	Measure the maximum available bandwidth towards the internet, in the download direction.
	Downloading a list of files via HTTP connections.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/bin/
	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_BIN) ./files/bin/bandwidth-test.lua $(1)/bin/bandwidth-test
	$(INSTALL_CONF) ./files/etc/config/bandwidth-test $(1)/etc/config/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
