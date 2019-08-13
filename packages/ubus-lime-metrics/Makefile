
include $(TOPDIR)/rules.mk

PKG_NAME:=ubus-lime-metrics
PKG_VERSION=$(GIT_COMMIT_DATE)-$(GIT_COMMIT_TSTAMP)
GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . )
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=ubus
  CATEGORY:=Ubus
  MAINTAINER:=Marcos Gutierrez <gmarcos87@gmail.com>
  SUBMENU:=3. Applications
  TITLE:=Metrics ubus module
  DEPENDS:= +lua +libubox-lua +libubus-lua +luci-lib-json +netperf
  PKGARCH:=all
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
	@chmod a+x $(1)/usr/libexec/rpcd/lime-metrics
	@chmod a+x $(1)/etc/uci-defaults/99-save-last-known-path-to-internet
	@chmod a+x $(1)/usr/sbin/last_internet
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
