include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=ubus
  CATEGORY:=Ubus
  MAINTAINER:=Marcos Gutierrez <gmarcos87@gmail.com>
  SUBMENU:=3. Applications
  TITLE:=B.A.T.M.A.N.-Adv ubus status module
  DEPENDS:= +batctl +lua +libubox-lua +libubus-lua +luci-lib-nixio +lime-system +luci-lib-jsonc
  PKGARCH:=all
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
