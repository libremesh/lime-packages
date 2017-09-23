#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-system
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

LIME_ID:=LiMe
LIME_RELEASE:=$(shell git branch | sed -n '/\* /s///p')
LIME_CODENAME:=development
LIME_BRANCH:=$(shell git branch | sed -n '/\* /s///p')
LIME_REVISION:=$(shell git log -n 1 --pretty=%h)
LIME_BUILDDATE:=$(shell date +%Y%m%d_%H%M)
LIME_DESCRIPTION:=$(LIME_ID) $(LIME_RELEASE) $(LIME_CODENAME) ($(LIME_BRANCH) rev. $(LIME_REVISION) $(LIME_BUILDDATE))

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=libremesh system files
  CATEGORY:=LiMe
  MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
  URL:=http://libremesh.org
  DEPENDS:=+libiwinfo-lua +lua +libuci-lua +luci-lib-ip +luci-lib-nixio
endef

define Package/$(PKG_NAME)/description
	Basic system files for LiMe node
endef

define Package/$(PKG_NAME)/conffiles
	/etc/config/lime
	/etc/config/lime-defaults
endef

define Build/Compile
endef

LIME_VERSION_SED:=$(SED)   's,%LIME_ID%,$(LIME_ID),g' \
			-e 's,%LIME_RELEASE%,$(LIME_RELEASE),g' \
			-e 's,%LIME_CODENAME%,$(LIME_CODENAME),g' \
			-e 's,%LIME_BRANCH%,$(LIME_BRANCH),g' \
			-e 's,%LIME_REVISION%,$(LIME_REVISION),g' \
			-e 's,%LIME_BUILDDATE%,$(LIME_BUILDDATE),g' \
			-e 's,%LIME_DESCRIPTION%,$(LIME_DESCRIPTION),g'

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
	$(LIME_VERSION_SED) \
		$(1)/etc/lime_release \
		$(1)/etc/uci-defaults/90_lime-banner
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || /etc/init.d/firewall-lime enable || true
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
