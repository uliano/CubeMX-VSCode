# Project Configuration
PROJECT_NAME = MyApp
TARGET = $(PROJECT_NAME)

# Toolchain Configuration
ARM_TOOLCHAIN_PATH = /opt/arm-gcc-15/bin
TOOLCHAIN_PREFIX = $(ARM_TOOLCHAIN_PATH)/arm-none-eabi-
CC = $(TOOLCHAIN_PREFIX)gcc
CXX = $(TOOLCHAIN_PREFIX)g++
AS = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
OBJDUMP = $(TOOLCHAIN_PREFIX)objdump
SIZE = $(TOOLCHAIN_PREFIX)size

# MCU Configuration (STM32G071xx)
MCU_ARCH = -mthumb -mcpu=cortex-m0plus

# Build directories
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj

# Auto-discover linker script
LINKER_SCRIPTS = $(shell find CubeMX -name "*.ld" -type f)
ifeq ($(LINKER_SCRIPTS),)
$(error No .ld files found in CubeMX directory)
endif
ifneq ($(words $(LINKER_SCRIPTS)),1)
$(error Multiple .ld files found: $(LINKER_SCRIPTS). Please specify one manually with LINKER_SCRIPT=path/to/file.ld)
endif
LINKER_SCRIPT = $(LINKER_SCRIPTS)

# Source file discovery
C_SOURCES = $(shell find Application src CubeMX/Core CubeMX/Drivers -name "*.c" -type f 2>/dev/null)
CXX_SOURCES = $(shell find Application src -name "*.cpp" -type f 2>/dev/null)
ASM_SOURCES = $(shell find CubeMX -name "*.s" -type f 2>/dev/null)

# Include directories discovery
INCLUDE_DIRS = $(sort $(dir $(shell find Application src CubeMX/Core CubeMX/Drivers -name "*.h" -o -name "*.hpp" -type f 2>/dev/null)))
INCLUDES = $(addprefix -I,$(INCLUDE_DIRS))

# Object files
C_OBJECTS = $(C_SOURCES:%.c=$(OBJ_DIR)/%.o)
CXX_OBJECTS = $(CXX_SOURCES:%.cpp=$(OBJ_DIR)/%.o)
ASM_OBJECTS = $(ASM_SOURCES:%.s=$(OBJ_DIR)/%.o)
OBJECTS = $(C_OBJECTS) $(CXX_OBJECTS) $(ASM_OBJECTS)

# DEPENDENCY TRACKING: Generate .d file list from objects
DEPS = $(C_OBJECTS:.o=.d) $(CXX_OBJECTS:.o=.d) $(ASM_OBJECTS:.o=.d)

# Compiler defines
DEFINES = -DUSE_HAL_DRIVER -DSTM32G071xx

# Compiler flags (RelWithDebInfo equivalent: -O2 -g -DNDEBUG)
COMMON_FLAGS = $(MCU_ARCH) -fdata-sections -ffunction-sections --specs=nano.specs -O2 -g -DNDEBUG
# DEPENDENCY TRACKING: Add -MMD -MP to generate .d files
CFLAGS = $(COMMON_FLAGS) -Wall -Wpedantic -Wno-unused-parameter -std=c11 -MMD -MP
CXXFLAGS = $(COMMON_FLAGS) -Wall -Wpedantic -Wno-unused-parameter -std=c++17 -fno-rtti -fno-exceptions -fno-threadsafe-statics -MMD -MP
ASFLAGS = $(MCU_ARCH) -g -MMD -MP

# Linker flags
LDFLAGS = $(MCU_ARCH) -T$(LINKER_SCRIPT) --specs=nosys.specs \
          -Wl,-Map=$(BUILD_DIR)/$(TARGET).map \
          -Wl,--gc-sections \
          -Wl,--start-group -lc -lm -lstdc++ -lsupc++ -Wl,--end-group \
          -Wl,--print-memory-usage

# Default target
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin $(BUILD_DIR)/$(TARGET).lst

# DEPENDENCY TRACKING: Include dependency files (if they exist)
# The - prefix tells make to ignore errors if .d files don't exist yet
-include $(DEPS)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Create object directories
$(OBJ_DIR)/%.o: %.c | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(DEFINES) $(INCLUDES) -c $< -o $@

$(OBJ_DIR)/%.o: %.cpp | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(DEFINES) $(INCLUDES) -c $< -o $@

$(OBJ_DIR)/%.o: %.s | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -c $< -o $@

# Link executable
$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS)
	@echo "Linking $@..."
	@$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	@$(SIZE) $@

# Generate hex file
$(BUILD_DIR)/$(TARGET).hex: $(BUILD_DIR)/$(TARGET).elf
	@echo "Creating $@..."
	@$(OBJCOPY) -O ihex $< $@

# Generate binary file
$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	@echo "Creating $@..."
	@$(OBJCOPY) -O binary $< $@

# Generate listing file with disassembly and source interleaved
$(BUILD_DIR)/$(TARGET).lst: $(BUILD_DIR)/$(TARGET).elf
	@echo "Creating $@..."
	@$(OBJDUMP) -h -S $< | sed '/^ *[0-9a-f][0-9a-f]*:/!{/^[0-9a-f][0-9a-f]* <.*>:/!s/^[[:space:]]*\(.\)/@ \1/}' > $@

# Flash firmware to device
flash: $(BUILD_DIR)/$(TARGET).elf
	@echo "Flashing $(TARGET)..."
	@st-flash write $(BUILD_DIR)/$(TARGET).bin 0x8000000

# Reset device
reset:
	@echo "Resetting device..."
	@st-flash reset

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)

# Generate compile_commands.json with bear
compile_commands: clean
	bear -- make all

# Debug info
info:
	@echo "Project: $(PROJECT_NAME)"
	@echo "Target: $(TARGET)"
	@echo "Linker script: $(LINKER_SCRIPT)"
	@echo "C sources ($(words $(C_SOURCES))): $(C_SOURCES)"
	@echo "C++ sources ($(words $(CXX_SOURCES))): $(CXX_SOURCES)"
	@echo "ASM sources ($(words $(ASM_SOURCES))): $(ASM_SOURCES)"
	@echo "Include dirs ($(words $(INCLUDE_DIRS))): $(INCLUDE_DIRS)"

.PHONY: all clean compile_commands info flash reset