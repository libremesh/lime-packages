#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_NAME:=lime-report
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=LibreMesh report utility
	CATEGORY:=LiMe
	MAINTAINER:=Ilario Gelmetti <iochesonome@gmail.com>
	URL:=https://libremesh.org
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Report utility for debugging LibreMesh
endef

define Package/$(PKG_NAME)/config
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(INSTALL_BIN) ./files/lime-report.sh $(1)/bin/lime-report
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
