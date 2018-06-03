#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=sprunge
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=sprunge.us pastebin
  SECTION:=utils
  CATEGORY:=Utilities
  MAINTAINER:=Ilario Gelmetti <ilario@eigenlab.org>
  URL:=http://sprunge.us
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	sprunge.us command line pastebin
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	@mkdir -p $(1)/usr/bin/ || true
	$(INSTALL_BIN) ./src/sprunge.sh $(1)/usr/bin/sprunge
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
