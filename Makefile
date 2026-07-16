ARCHS := arm64
TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES := extrahook

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := extrahook



extrahook_USE_MODULES := 0
extrahook_FILES += $(wildcard objc_base/*.mm objc_base/*.m)
extrahook_FILES += $(wildcard cheat/*.mm cheat/*.m)
extrahook_FILES += imgui/ImGuiDrawView.mm
extrahook_FILES += imgui/ESPImGuiView.mm
extrahook_FILES += $(wildcard imgui/IMGUI/*.cpp)
extrahook_FILES += $(wildcard imgui/IMGUI/*.mm)
extrahook_FILES += $(wildcard esp/helpers/*.mm)
extrahook_FILES += $(wildcard esp/unity_api/*.mm)
extrahook_CFLAGS += -fobjc-arc -Wno-unused-function -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value -Wno-module-import-in-extern-c -Wno-mismatched-return-types -Wno-nontrivial-memcall
extrahook_CFLAGS += -Iinclude
extrahook_CFLAGS += -Iimgui
extrahook_CFLAGS += -Iesp
extrahook_CFLAGS += -include hud-prefix.pch
extrahook_CCFLAGS += -DNOTIFY_LAUNCHED_HUD=\"ch.xxtou.notification.hud.launched\"
extrahook_CCFLAGS += -DNOTIFY_DISMISSAL_HUD=\"ch.xxtou.notification.hud.dismissal\"
extrahook_CCFLAGS += -DNOTIFY_RELOAD_HUD=\"ch.xxtou.notification.hud.reload\"
extrahook_CCFLAGS += -DNOTIFY_RELOAD_APP=\"ch.xxtou.notification.app.reload\"
extrahook_CCFLAGS += -std=c++17
MainApplication.mm_CCFLAGS += -std=c++14
extrahook_FRAMEWORKS += CoreGraphics QuartzCore UIKit Foundation Metal MetalKit
extrahook_PRIVATE_FRAMEWORKS += BackBoardServices GraphicsServices IOKit SpringBoardServices


TARGET_CODESIGN_FLAGS = -Sent.plist

include $(THEOS_MAKE_PATH)/application.mk

after-stage::
	$(ECHO_NOTHING)mkdir -p packages $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cp -rp $(THEOS_STAGING_DIR)/Applications/extrahook.app $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cd $(THEOS_STAGING_DIR); zip -qr extrahook.tipa Payload; cd -;$(ECHO_END)
	$(ECHO_NOTHING)mv $(THEOS_STAGING_DIR)/extrahook.tipa packages/extrahook.tipa $(ECHO_END)



