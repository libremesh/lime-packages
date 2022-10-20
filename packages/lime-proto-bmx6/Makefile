include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=lime
  CATEGORY:=LibreMesh
  TITLE:=LiMe Bmx6 proto support
  DEPENDS:=+bmx6 +bmx6-json +bmx6-sms +bmx6-table +bmx6-uci-config \
           +iptables +lime-system +lua +libuci-lua \
           +kmod-ebtables-ipv6 +ebtables +luci-lib-jsonc \
	   +luci-lib-nixio
  MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
  VERSION:=$(if $(PKG_VERSION),$(PKG_VERSION),$(PKG_SRC_VERSION))
  PKGARCH:=all
  URL:=https://github.com/libremesh/lime-packages/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
