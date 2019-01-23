#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-paste
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=libremesh paste utils
	CATEGORY:=LiMe
	MAINTAINER:=Paul Spooren <mail@aparcar.org>
	URL:=https://libremesh.org
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Paste utility for LibreMesh
endef

define Package/$(PKG_NAME)/config
	select BUSYBOX_CUSTOM
	select BUSYBOX_CONFIG_NC
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(INSTALL_BIN) ./files/lime-paste.sh $(1)/bin/lime-paste
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
