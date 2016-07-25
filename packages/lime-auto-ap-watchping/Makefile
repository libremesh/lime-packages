# 
# Copyright (C) 2016 Libre-Mesh.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-auto-ap-watchping
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=Automatic AP failing ssid control based on watchping
  SECTION:=lime
  CATEGORY:=LiMe
  MAINTAINER:=Pau Escrich <p4u@dabax.et>
  URL:=http://libre-mesh.org
  DEPENDS:=+watchping 
endef

define Package/$(PKG_NAME)/description
	Watchping hooks and daemon for automatic AP ssid changing if network problems
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
