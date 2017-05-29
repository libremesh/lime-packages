# 
# Copyright (C) 2017 Ilario Gelmetti
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-docs-minimal
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=LiMe
  TITLE:=LibreMesh minimal documentation
  MAINTAINER:=Ilario Gelmetti <ilario@tgnu.ml>
  URL:=http://libremesh.org/docs/
endef

define Package/$(PKG_NAME)/description
Minimal offline documentation for LibreMesh firmware containing
just an expaination of the main config file.
endef

DOCS_FILE:=config.txt

define Download/docs
  FILE:=$(DOCS_FILE)
  URL:=https://raw.githubusercontent.com/libremesh/lime-web/master/docs
endef
$(eval $(call Download,docs))

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/docs/
	$(INSTALL_BIN) $(DL_DIR)/$(DOCS_FILE) $(1)/docs/
endef

$(eval $(call BuildPackage,lime-docs-minimal))

