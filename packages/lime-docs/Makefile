# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2017 Ilario Gelmetti

include $(TOPDIR)/rules.mk

# Pinned upstream docs content. Do not derive PKG_VERSION from *this*
# repository's git history for packages/lime-docs: every Makefile commit would
# change PKG_SOURCE_SUBDIR and invalidate PKG_MIRROR_HASH under OpenWrt 24.10
# reproducible tarball rules (and gh-action-sdk runs `make package/.../check`).
PKG_NAME:=lime-docs
PKG_SOURCE_VERSION:=3b580071fde1a817837a596fd41ae4bf7797ab1d
# Commit date of PKG_SOURCE_VERSION on libremesh.github.io + short sha suffix.
PKG_VERSION:=2026.04.07~3b58007

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/libremesh/libremesh.github.io/
PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBMODULES:=skip
PKG_MIRROR_HASH:=6975fe2a33bea711631c5b4e5311186b6b32a0cc3164b1ccc9d89b840361bcb1
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
