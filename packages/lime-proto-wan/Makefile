include ../../libremesh.mk

define Package/$(PKG_NAME)
  SECTION:=lime
  CATEGORY:=LibreMesh
  TITLE:=LiMe wan proto support
  DEPENDS:=+lime-system +lua +libuci-lua +kmod-ipt-nat +iptables
  MAINTAINER:=Gioacchino Mazzurco <gio@eigenlab.org>
  VERSION:=$(if $(PKG_VERSION),$(PKG_VERSION),$(PKG_SRC_VERSION))
  PKGARCH:=all
  URL:=https://github.com/libremesh/lime-packages/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
