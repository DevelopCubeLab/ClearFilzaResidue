ARCHS := arm64
TARGET := iphone:clang:latest:12.2

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = ClearFilzaResidue

include $(THEOS_MAKE_PATH)/xcodeproj.mk

# 在打包阶段用ldid签名赋予权力，顺便删除_CodeSignature
before-package::
	@if [ -f $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/Info.plist ]; then \
		echo -e "\033[32mSigning with ldid...\033[0m"; \
		ldid -Sentitlements.plist $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app; \
	else \
		@echo -e "\033[31mNo Info.plist found. Skipping ldid signing.\033[0m"; \
	fi
	@echo -e "\033[32mRemoving _CodeSignature folder..."
	@rm -rf $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/_CodeSignature

# 包装完成后重命名为 .tipa
after-package::
	@echo -e "\033[32mRenaming .ipa to .tipa...\033[0m"
	@mv ./packages/com.developlab.idisktidy.clearfilzaresidue_1.0.ipa ./packages/com.developlab.idisktidy.clearfilzaresidue_1.0.tipa || @echo -e "\033[31mNo .ipa file found.\033[0m"
	@echo -e "\033[1;32m\n** Build Succeeded **\n\033[0m"
