include $(TOPDIR)/rules.mk

PKG_NAME?=$(notdir ${CURDIR})

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

