export THEOS ?= /opt/theos

ARCHS  = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GameOverlayMenu

GameOverlayMenu_FILES = Tweak.xm \
                        src/FeatureManager.m \
                        src/RuntimeScanner.m \
                        src/OverlayMenuController.m

GameOverlayMenu_FRAMEWORKS = UIKit Foundation
GameOverlayMenu_CFLAGS     = -fobjc-arc -Wno-unused-variable -Isrc

include $(THEOS_MAKE_PATH)/tweak.mk
