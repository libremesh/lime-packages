include $(TOPDIR)/rules.mk

LIME_NAME=$(notdir ${CURDIR})

PKG_NAME?=$(LIME_NAME)
PKG_MAINTAINER?=$(LIME_MAINTAINER)

# from https://github.com/openwrt/luci/blob/master/luci.mk
PKG_VERSION?=$(if $(DUMP),x,$(strip $(shell \
	if svn info >/dev/null 2>/dev/null; then \
		revision="svn-r$$(LC_ALL=C svn info | sed -ne 's/^Revision: //p')"; \
	elif git log -1 >/dev/null 2>/dev/null; then \
		revision="svn-r$$(LC_ALL=C git log -1 | sed -ne 's/.*git-svn-id: .*@\([0-9]\+\) .*/\1/p')"; \
		if [ "$$revision" = "svn-r" ]; then \
			set -- $$(git log -1 --format="%ct %h" --abbrev=7); \
			secs="$$(($$1 % 86400))"; \
			yday="$$(date --utc --date="@$$1" "+%y.%j")"; \
			revision="$$(printf 'git-%s.%05d-%s' "$$yday" "$$secs" "$$2")"; \
		fi; \
	else \
		revision="unknown"; \
	fi; \
	echo "$$revision" \
)))
PKG_RELEASE?=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=$(if $(LIME_SECTION),$(LIME_SECTION),lime)
  CATEGORY:=$(if $(LIME_CATEGORY),$(LIME_CATEGORY),LibreMesh)
  TITLE:=$(LIME_TITLE)
  DEPENDS:=+lime-system $(LIME_DEPENDS)
  VERSION:=$(if $(PKG_VERSION),$(PKG_VERSION),$(PKG_SRC_VERSION))
  PKGARCH:=all
  URL:=https://github.com/libremesh/lime-packages/
endef

ifneq ($(LIME_DESCRIPTION),)
 define Package/$(PKG_NAME)/description
   $(strip $(LIME_DESCRIPTION))
 endef
endif

define Build/Compile
	@rm -rf ./build || true
	@mkdir ./build
	$(CP) ./files ./build
	$(FIND) ./build -name '*.sh' -exec sed -i '/^\s*#\[Doc\]/d' {} +
	$(FIND) ./build -name '*.lua' -exec sed -i '/^\s*--!.*/d' {} +
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./build/files/* $(1)/
endef

define Build/Configure
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
