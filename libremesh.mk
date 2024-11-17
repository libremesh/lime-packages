include $(TOPDIR)/rules.mk

PKG_NAME?=$(notdir ${CURDIR})

GIT_COMMIT_DATE:=$(shell git log -n 1 --pretty=%ad --date=short . | sed 's|-|.|g')
GIT_COMMIT_TSTAMP:=$(shell git log -n 1 --pretty=%at . )

PKG_SRC_VERSION:=$(GIT_COMMIT_DATE)~$(GIT_COMMIT_TSTAMP)
PKG_VERSION:=$(if $(PKG_VERSION),$(PKG_VERSION),$(PKG_SRC_VERSION))

PKG_BUILD_DIR:=$(if $(PKG_BUILD_DIR),$(PKG_BUILD_DIR),$(BUILD_DIR)/$(PKG_NAME))

include $(INCLUDE_DIR)/package.mk

define Build/Compile
	@rm -rf ./build || true
	@mkdir ./build
	$(CP) ./files ./build
	$(FIND) ./build -name '*.sh' -exec sed -i '/^\s*#\[Doc\]/d' {} +
	$(FIND) ./build -name '*.lua' -exec sed -i '/^\s*--!.*/d' {} +
	$(FIND) ./build -type f -executable -exec sed -i '/^\s*#\[Doc\]/d' {} +
	$(FIND) ./build -type f -executable -exec sed -i '/^\s*--!.*/d' {} +
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./build/files/* $(1)/
endef

define Build/Configure
endef

