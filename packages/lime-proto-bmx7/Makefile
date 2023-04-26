include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=lime
  CATEGORY:=LibreMesh
  TITLE:=LiMe Bmx7 proto support
  DEPENDS:=+bmx7 +bmx7-json +bmx7-sms +bmx7-table +bmx7-uci-config +bmx7-tun \
           +lime-system +lua +libuci-lua +kmod-ebtables-ipv6 +ebtables-nft \
	   +luci-lib-nixio
  MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
  VERSION:=$(if $(PKG_VERSION),$(PKG_VERSION),$(PKG_SRC_VERSION))
  PKGARCH:=all
  URL:=https://github.com/libremesh/lime-packages/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
