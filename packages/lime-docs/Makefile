# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2017 Ilario Gelmetti

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . | sed 's|-|.|g' )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-docs
PKG_VERSION=$(GIT_COMMIT_DATE)~$(GIT_COMMIT_TSTAMP)

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/libremesh/libremesh.github.io/
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=HEAD
PKG_SOURCE_SUBMODULES:=skip
PKG_MIRROR_HASH:=skip
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=LibreMesh
  TITLE:=LibreMesh documentation
  DEPENDS:=+$(PKG_NAME)-minimal
  MAINTAINER:=Ilario Gelmetti <iochesonome@gmail.com>
  URL:=https://libremesh.org/docs/
  SUBMENU:=Offline Documentation
  PKGARCH:=all
endef

define Package/$(PKG_NAME)-minimal
  CATEGORY:=LibreMesh
  TITLE:=LibreMesh minimal documentation
  MAINTAINER:=Ilario Gelmetti <iochesonome@gmail.com>
  URL:=https://libremesh.org/docs/
  SUBMENU:=Offline Documentation
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
Offline documentation for LibreMesh firmware
endef

define Package/$(PKG_NAME)-minimal/description
Minimal offline English documentation for LibreMesh firmware containing
just a commented example of the main config file.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/docs/
	$(FIND) $(PKG_BUILD_DIR)/docs/{guide,reference} -name "*.md" | while read file_name; do \
		to_name="$$$${file_name/.md}.txt"; \
		to_name="$$$${to_name/*\/docs\/}"; \
		mkdir -p $(1)/www/docs/$$$$(dirname $$$$to_name); \
		$(CP) $$$$file_name $(1)/www/docs/$$$$to_name ; done
	@ln -s /www/docs $(1)/docs
endef

define Package/$(PKG_NAME)-minimal/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
	@ln -s /www/docs $(1)/docs
endef

$(eval $(call BuildPackage,lime-docs))
$(eval $(call BuildPackage,lime-docs-minimal))
