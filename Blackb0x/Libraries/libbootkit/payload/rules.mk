ARM_CC ?= clang
ARM_OBJCOPY ?= llvm-objcopy


ARM_CC_FULL = $(TOOLCHAIN)/$(ARM_CC)
ARM_CFLAGS = -mthumb
ARM_CFLAGS += -march=armv7-a
ARM_CFLAGS += -fno-builtin -nostdlib

ARM_OBJCOPY_FULL = $(TOOLCHAIN)/$(ARM_OBJCOPY)


PAYLOAD_DIR = $(LIBBOOTKIT_DIR)/payload

PAYLOAD_BIN = $(BUILD_PATH)/$(PAYLOAD_DIR)/payload.bin

PAYLOAD_SRC = $(PAYLOAD_DIR)/payload.S
PAYLOAD_OBJECT = $(addprefix $(BUILD_PATH)/, $(PAYLOAD_SRC:.S=.o))


$(PAYLOAD_BIN): $(PAYLOAD_OBJECT)
	@echo "\tbuilding payload"
	@$(DIR_HELPER)
	@$(ARM_OBJCOPY_FULL) -O binary $< $@

$(PAYLOAD_OBJECT): $(PAYLOAD_SRC)
	@$(DIR_HELPER)
	@$(ARM_CC_FULL) $(ARM_CFLAGS) -o $@ $<
