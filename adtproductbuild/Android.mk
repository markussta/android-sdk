# Copyright 2012 The Android Open Source Project
#
# Makefile rules to build the ADT Eclipse IDE.
# This is invoked from sdk/eclipse/scripts/build_server.sh using
# something like "make PRODUCT-sdk-adt_eclipse_ide".
#
# Expected env vars:
# ADT_IDE_DEST_DIR:  existing directory where to copy the IDE zip files.
# ADT_IDE_ZIP_QUALIFIER: either a date or build number to incorporate in the zip names.

# Expose the ADT Eclipse IDE build only for the SDK when building adt_eclipse_ide
ifneq (,$(is_sdk_build)$(filter sdk sdk_x86 sdk_mips,$(TARGET_PRODUCT)))
ifneq (,$(filter adt_eclipse_ide,$(MAKECMDGOALS)))

LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := adt_eclipse_ide
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_IS_HOST_MODULE := true
include $(BUILD_SYSTEM)/base_rules.mk

ADT_IDE_MODULE_DEPS := $(TOPDIR)sdk/adtproductbuild/$(LOCAL_MODULE)

ADT_IDE_BUILD_LOG    := $(TOPDIR)out/host/eclipse/adtproduct/adtproduct.log
ADT_IDE_ARTIFACT_DIR := $(TOPDIR)out/host/eclipse/adtproduct/pbuild/I.RcpBuild
ADT_IDE_RELEASE_DIR  := $(TOPDIR)out/host/eclipse/adtproduct/release

ADT_IDE_JAVA_LIBS := $(shell $(TOPDIR)sdk/eclipse/scripts/create_all_symlinks.sh -d)
ADT_IDE_JAVA_DEPS := $(foreach m,$(ADT_IDE_JAVA_LIBS),$(HOST_OUT_JAVA_LIBRARIES)/$(m).jar)

ADT_IDE_JAVA_TARGET := $(ADT_IDE_RELEASE_DIR)/adt_eclipse_ide_java_build
ADT_VERSION := $(shell grep Bundle-Version $(TOPDIR)sdk/eclipse/plugins/com.android.ide.eclipse.adt/META-INF/MANIFEST.MF | sed 's/.*: \([0-9]\+.[0-9]\+.[0-9]\+\).*/\1/')

# Common not-quite-phony rule to perform the eclipse build only once
# This invokes the java builder on eclipse. It generates multiple
# zipped versions (one per OS, all built at the same time)
# of the ide as specified in the build.properties file.
$(ADT_IDE_JAVA_TARGET) : $(TOPDIR)sdk/adtproductbuild/adt_eclipse_ide \
			 $(TOPDIR)sdk/adtproductbuild/build.xml \
			 $(TOPDIR)sdk/adtproductbuild/build.properties \
			 $(ADT_IDE_JAVA_DEPS)
	@if [[ ! -d $(TOPDIR)prebuilts/eclipse-build-deps ]]; then \
		echo "*** [adt_eclipse_ide] ERROR: Missing prebuilts/eclipse-build-deps directory. Make sure to run 'repo init -g all;repo sync' first."; \
		exit 1; \
	fi
	$(hide)rm -rf $(TOPDIR)out/host/eclipse/adtproduct/fbuild/plugins
	$(hide)rm -rf $(TOPDIR)out/host/eclipse/adtproduct/pbuild/plugins
	$(hide)mkdir -p $(dir $@)
	$(hide)$(TOPDIR)sdk/eclipse/scripts/create_all_symlinks.sh -c
	$(hide)cd $(TOPDIR)sdk/adtproductbuild && \
		rm -f ../../$(ADT_IDE_BUILD_LOG) && mkdir -p ../../$(dir $(ADT_IDE_BUILD_LOG)) && \
		( java -jar ../../external/eclipse-basebuilder/basebuilder-3.6.2/org.eclipse.releng.basebuilder/plugins/org.eclipse.equinox.launcher_1.1.0.v20100507.jar \
			org.eclipse.equinox.launcher.Main \
			-application org.eclipse.ant.core.antRunner \
			-configuration ../../out/host/eclipse/adtproduct/ant-configuration \
			-data ../../out/host/eclipse/adtproduct/ant-workspace \
			2>&1 && \
		  mv -f ../../$(ADT_IDE_BUILD_LOG) ../../$(ADT_IDE_BUILD_LOG).1 ) \
		| tee ../../$(ADT_IDE_BUILD_LOG) \
		| sed 's/^/IDE: /'; \
		if [[ -f ../../$(ADT_IDE_BUILD_LOG) ]]; then \
		  echo "ADT IDE build failed. Full log:" ; \
		  cat ../../$(ADT_IDE_BUILD_LOG) ; \
		  exit 1 ; \
		fi
	$(hide)$(ACP) -fp $(V) $(TOPDIR)sdk/adtproductbuild/adt_eclipse_ide $@

# Defines the zip filename generated for an OS specific android IDE.
define adt-ide-zip
$(ADT_IDE_RELEASE_DIR)/android-ide-$(ADT_IDE_ZIP_QUALIFIER)-$(1).$(2).zip
endef

# Defines the rule needed to make one of the OS specific android IDE.
# If ADT_IDE_DEST_DIR it also defines the rule to produce the final dest zip.
# $1 = the platform (linux|macosx|win32).(gtk|cocoa|win32)
# $2 = the architecture (x86 or x8_64).
# $3 = the src zip (from out/host/eclipse/artifacts/RcpBuild-...)
# $4 = the destination directory (where the unpacked eclipse is created)
# $5 = the destination zip with the zipped eclipse ide.
define mk-adt-ide-2
$(5): $(ADT_IDE_JAVA_TARGET)
	$(hide) \
	rm -rf $(V) $(4) && \
	rm  -f $(V) $(5) && \
	mkdir -p $(4) && \
	unzip -q $(3) -d $(4) && \
	if [[ "$(1)" == "macosx.cocoa" ]]; then \
	  mv $(4)/eclipse/eclipse.app/Contents/MacOS/eclipse.ini $(4)/eclipse/Eclipse.app/Contents/MacOS && \
	  rm -rf $(4)/eclipse/eclipse.app && \
	  rm -r  $(4)/eclipse/eclipse && \
	  chmod +x $(4)/eclipse/Eclipse.app/Contents/MacOS/eclipse && \
	  cp $(4)/eclipse/plugins/com.android.ide.eclipse.adt.package*/icons/adt.icns \
	     $(4)/eclipse/Eclipse.app/Contents/Resources && \
	  sed -i -e 's/Eclipse.icns/adt.icns/g' $(4)/eclipse/Eclipse.app/Contents/MacOS/eclipse.ini && \
	  sed -i -e 's/Eclipse.icns/adt.icns/g' $(4)/eclipse/Eclipse.app/Contents/Info.plist ; \
	fi && \
	sed -i -e 's/org.eclipse.platform/com.android.ide.eclipse.adt.package.product/g' \
	  $(4)/eclipse/$(if $(filter macosx.cocoa,$(1)),Eclipse.app/Contents/MacOS/)eclipse.ini && \
	echo "-Declipse.buildId=v$(ADT_VERSION)-$(ADT_IDE_ZIP_QUALIFIER)" >> \
	  $(4)/eclipse/$(if $(filter macosx.cocoa,$(1)),Eclipse.app/Contents/MacOS/)eclipse.ini && \
	sed -i -e "s/buildId/v$(ADT_VERSION)-$(ADT_IDE_ZIP_QUALIFIER)/g" \
	  $(4)/eclipse/plugins/com.android.ide.eclipse.adt.package_*/about.mappings && \
	sed -i -e 's/org.eclipse.platform.ide/com.android.ide.eclipse.adt.package.product/g' \
	       -e 's/org.eclipse.platform/com.android.ide.eclipse.adt.package/g' \
	  $(4)/eclipse/configuration/config.ini
	$(hide)cd $(4) && zip -9rq ../$(notdir $(5)) eclipse
ifneq (,$(ADT_IDE_DEST_DIR))
$(ADT_IDE_DEST_DIR)/$(notdir $(5)): $(5)
	@mkdir -p $(ADT_IDE_DEST_DIR)
	$(hide)cp $(V) $(5) $(ADT_IDE_DEST_DIR)/$(notdir $(5))
	@echo "ADT IDE copied to $(ADT_IDE_DEST_DIR)/$(notdir $(5))"
else
	@echo "ADT IDE available at $(5)"
endif
endef

# Defines the rule needed to make one of the OS specific android IDE.
# This is just a convenience wrapper that calls mk-adt-ide-2 and presets
# the source and destination zip paths.
# It also sets the dependencies we need to produce the final dest zip.
# $1 = the platform (linux|macosx|win32).(gtk|cocoa|win32)
# $2 = the architecture (x86 or x8_64).
define mk-adt-ide
$(call mk-adt-ide-2,$(1),$(2), \
    $(ADT_IDE_ARTIFACT_DIR)/RcpBuild-$(1).$(2).zip, \
    $(ADT_IDE_RELEASE_DIR)/android-ide-$(1).$(2), \
    $(call adt-ide-zip,$(1),$(2)))
ADT_IDE_MODULE_DEPS += $(call adt-ide-zip,$(1),$(2))
ifneq (,$(ADT_IDE_DEST_DIR))
ADT_IDE_MODULE_DEPS += $(ADT_IDE_DEST_DIR)/$(notdir $(call adt-ide-zip,$(1),$(2)))
endif
endef

$(eval $(call mk-adt-ide,linux.gtk,x86_64))
$(eval $(call mk-adt-ide,macosx.cocoa,x86_64))
$(eval $(call mk-adt-ide,win32.win32,x86_64))

# This rule triggers the build of the 3 ide zip files.
# The adt_eclipse_ide script is currently a platceholder used
# to detect when the build was completed. We may use it later
# as a launch script.
$(LOCAL_BUILT_MODULE) : $(ADT_IDE_MODULE_DEPS)
	@mkdir -p $(dir $@)
	$(hide)$(ACP) -fp $(V) $(TOPDIR)sdk/adtproductbuild/adt_eclipse_ide $@
	@echo "Packing of ADT IDE done"

endif
endif

