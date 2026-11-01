TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
INSTALL_TARGET_PROCESSES = FreeFire

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HyzzFFZ
HyzzFFZ_FILES = Tweak.xm
HyzzFFZ_CFLAGS = -fobjc-arc
HyzzFFZ_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
