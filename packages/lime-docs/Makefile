# 
# Copyright (C) 2017 Ilario Gelmetti
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-docs
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/libremesh/lime-web/trunk/docs
PKG_SOURCE_PROTO:=svn
PKG_SOURCE_VERSION:=HEAD
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=LiMe
  TITLE:=LibreMesh documentation
  MAINTAINER:=Ilario Gelmetti <ilario@tgnu.ml>
  URL:=http://libremesh.org/docs/
endef

define Package/$(PKG_NAME)/description
Offline documentation for LibreMesh firmware,
includes lime-docs-minimal contents
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/docs/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/*txt $(1)/docs/
	@cp -r $(PKG_BUILD_DIR)/hardware/ $(1)/docs/
endef

$(eval $(call BuildPackage,lime-docs))

