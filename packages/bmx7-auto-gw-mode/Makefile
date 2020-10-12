# 
# Copyright (C) 2014 Pau Escrich
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=bmx7-auto-gw-mode
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=LibreMesh
  TITLE:=bmx7 auto Internet gateway module 
  MAINTAINER:=Pau Escrich <p4u@dabax.et>
  URL:=http://libremesh.org
  DEPENDS:= bmx7 +watchping +ip
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Watchping hooks to set bmx7 Internet automatic announcements
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
