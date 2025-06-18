include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=SSH
  MAINTAINER:=Nicolas Pace <nicopace@altermundi.net>
  TITLE:=tmate.io ubus bindings
  DEPENDS:=+tmate +lime-system +luci-lib-jsonc
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	It allows to create remote sessions over tmate through ubus.
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
