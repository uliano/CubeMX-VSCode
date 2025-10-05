# STM32 Makefile Development Environment

A clean, maintainable STM32 development setup using Make, VS Code, and CubeMX with minimal manual intervention.

## Project Structure

```
├── Application/         # User application code
├── src/                 # User libraries and utilities
├── CubeMX/              # CubeMX generated code (do not edit manually)
├── .vscode/             # VS Code configuration
├── build/               # Build artifacts (auto-generated)
├── Makefile             # Build system configuration
└── STM32XXXX.svd        # SVD file for register debugging
```

## Features

- **Auto-discovery**: Linker scripts and source files found automatically
- **Clean separation**: User code isolated from CubeMX generated code
- **Regeneration-safe**: CubeMX regeneration preserves user code
- **Multi-MCU ready**: Easy to switch between different STM32 families
- **Dependency tracking**: Automatic rebuilds when headers change
- **Smart linker script detection**: Validates single .ld file or reports conflicts

## Initial Setup

### 1. Configure ARM Toolchain Path

Set the path to your ARM GCC toolchain in the `Makefile`. Edit the `ARM_TOOLCHAIN_PATH` variable:

```make
ARM_TOOLCHAIN_PATH = /opt/arm-gcc-15/bin
```

### 2. Create CubeMX Project

1. **Clean the CubeMX directory** when changing microcontroller
2. Open STM32CubeMX and create new project in `CubeMX/` folder
3. Configure your MCU pins and peripherals
4. **Important**: In Code Generation settings:
   - Set "Copy only the necessary library files"
   - Set "Generate peripheral initialization as a pair of '.c/.h' files per peripheral"
5. Generate code

### 3. Modify CubeMX Generated main.c

Add these modifications to `CubeMX/Core/Src/main.c` in the designated USER CODE sections:

```c
/* USER CODE BEGIN 0 */
extern void app_main(void);
/* USER CODE END 0 */
```

```c
/* USER CODE BEGIN 2 */
app_main();
/* USER CODE END 2 */
```

**Note**: These modifications are preserved across CubeMX regenerations when placed in USER CODE sections.

### 4. Download SVD File

1. Download the appropriate SVD file for your microcontroller:
   - **GitHub**: [STM32 SVD Files Collection](https://github.com/modm-io/cmsis-svd-stm32)
   - **ST Official**: Search "STM32XXXX SVD" on ST website
2. Place it in the project root with a descriptive name (e.g., `STM32G071.svd`)

### 5. Disconnect from Template Repository

Remove the connection to the template repository:

```bash
git remote remove origin
```

**Optional**: Create and connect to a new GitHub repository for your project:

```bash
# Create new repository on GitHub
gh repo create my-project-name --private

# Connect to the new repository (choose one):
# HTTPS (requires token authentication on each push)
git remote add origin https://github.com/yourusername/my-project-name.git

# SSH (requires initial setup, then no authentication needed)
git remote add origin git@github.com:yourusername/my-project-name.git
```

### 6. Enable Tracking of Generated Files

For your project development, modify `.gitignore` to track CubeMX generated files and SVD files by commenting out or removing these lines:

```gitignore
# CubeMX/*
# !CubeMX/*.ioc
# *.svd
```

This ensures all necessary files are versioned in your project repository.

### 7. Update VS Code Configuration

Edit `.vscode/launch.json` and `.vscode/c_cpp_properties.json` to match your MCU:

**launch.json** - Update device and svdFile in all configurations:
```json
"device": "STM32F401xC",
"svdFile": "STM32F401.svd"
```

**c_cpp_properties.json** - Update defines:
```json
"defines": [
    "USE_HAL_DRIVER",
    "STM32F401xC"
]
```

### 8. Update MCU Parameters

**CRITICAL**: When using a different microcontroller, you **MUST** update the MCU architecture and compiler defines in the Makefile, otherwise the build will fail.

Edit the Makefile:

**MCU Architecture:**
```make
# MCU Configuration
MCU_ARCH = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
```

Common architectures:
- **Cortex-M0+**: `-mthumb -mcpu=cortex-m0plus` (STM32G0, STM32L0)
- **Cortex-M3**: `-mthumb -mcpu=cortex-m3` (STM32F1, STM32L1)
- **Cortex-M4**: `-mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16` (STM32F4, STM32L4)
- **Cortex-M7**: `-mthumb -mcpu=cortex-m7 -mfloat-abi=hard -mfpu=fpv5-d16` (STM32F7, STM32H7)

**Compiler Defines:**
```make
# Compiler defines
DEFINES = -DUSE_HAL_DRIVER -DSTM32F401xC
```

Change to match your exact MCU model.

**Warning**: Mismatched architecture settings will cause compilation errors with missing intrinsic functions like `__LDREXW` and `__STREXW`.

## Build and Debug

```bash
# Build project
make

# Build specific target
make build/firmware.elf   # Executable
make build/firmware.hex   # Intel HEX
make build/firmware.bin   # Binary
make build/firmware.lst   # Assembly listing with source

# Clean build
make clean

# Generate compile_commands.json for Clangd
make compile_commands

# Flash firmware to device (ST-Link)
make flash-st

# Flash firmware to device (Black Magic Probe)
make flash-bmp

# Flash firmware to device (J-Link)
make flash-jlink

# Show project information
make info

# Debug with VS Code
# 6 configurations available: ST-Link, BMP, J-Link
# Each with Run (flash+debug) and Attach (debug only) modes
```

## Development Workflow

### Tasks Menu

You can access build functions via:
- **Ctrl+Shift+P** → "Tasks: Run Task"
- Or Terminal menu → "Run Task..."

Available tasks:
- Build Project
- Clean Project
- Flash Firmware

### Makefile Features

#### Automatic Source Discovery
The Makefile automatically discovers source files in:
- `Application/` - `.c` and `.cpp` files
- `src/` - `.c` and `.cpp` files
- `CubeMX/Core/` - `.c` files and `.s` assembly files
- `CubeMX/Drivers/` - `.c` files

#### Dependency Tracking
- Automatically tracks header dependencies for all source files
- Rebuilds only affected files when headers change
- Works for C, C++, and assembly files

#### Linker Script Detection
- Automatically finds `.ld` files in `CubeMX/` directory
- Validates exactly one linker script exists
- Clear error messages for missing or multiple scripts

#### Build Output
- Clean, informative build messages
- Memory usage summary after linking
- Size information for text, data, and BSS sections

## User Code Organization

### Application/
Main application code that calls hardware abstractions and implements business logic.

- `app_main.c` - Main application entry point (called from CubeMX main)
- `printf_redirect.c` - Printf redirection to UART

### src/
Reusable libraries, drivers, and utilities.

- Hardware abstraction layers
- Protocol implementations
- Utility functions

## Key Benefits

1. **CubeMX Regeneration Safe**: User code is completely separated from generated code
2. **Automatic Discovery**: No manual path management for source files and linker scripts
3. **Clean Organization**: Clear separation between generated and user code
4. **Easy MCU Migration**: Minimal changes needed to switch microcontrollers
5. **Smart Dependency Tracking**: Efficient rebuilds when headers change
6. **Simple Build System**: Standard Make commands, no complex configuration

## Manual Steps When Changing MCU

1. Clean `CubeMX/` directory
2. Generate new CubeMX project
3. Add `app_main()` calls to generated main.c
4. Download new SVD file
5. Update `launch.json` with new MCU name and SVD file (all configurations)
6. Update `c_cpp_properties.json` with new MCU defines
7. Update `Makefile` MCU parameters (CPU arch and defines)

## VS Code Configuration

### Extensions
The project includes pre-configured extension recommendations in `.vscode/extensions.json`:

**Essential:**
- **C/C++** (`ms-vscode.cpptools`) - IntelliSense for C/C++ (default configuration)
- **Cortex-Debug** (`marus25.cortex-debug`) - ARM debugging with ST-Link and Black Magic Probe support

**Optional:**
- **clangd** (`llvm-vs-code-extensions.vscode-clangd`) - Alternative language server (faster, more accurate)
- **Clang-Format** (`xaver.clang-format`) - Automatic code formatting
- **Arm Assembly** (`dan-c-underwood.arm`) - Syntax highlighting for .lst files

### IntelliSense Configuration

By default, the project uses **C/C++ IntelliSense** configured via `c_cpp_properties.json`.

**To switch to clangd** (faster, more accurate):
1. Install the clangd extension
2. Uncomment the clangd settings in `.vscode/settings.json`
3. Reload VS Code

### Automatic Configuration
- **c_cpp_properties.json**: Pre-configured for C/C++ IntelliSense with correct paths and defines
- **compile_commands.json**: Generated with `make compile_commands` (optional, works with both IntelliSense and clangd)
- **Syntax Highlighting**: .lst files automatically associated with ARM assembly syntax

## Debug Configurations

The project includes 6 complete debug configurations for VS Code:

### ST-Link (via stlink-tools)
- **ST-Link Run**: Flash firmware and debug from main
- **ST-Link Attach**: Attach to running firmware

### Black Magic Probe
- **Black Magic Probe Run**: Flash firmware and debug from main (includes built-in UART on `/dev/ttyACM1`)
- **Black Magic Probe Attach**: Attach to running firmware

### J-Link (via SEGGER JLinkGDBServer)
- **J-Link Run**: Flash firmware and debug from main
- **J-Link Attach**: Attach to running firmware

### Makefile Flash Commands

```bash
make flash-st    # Flash via ST-Link
make flash-bmp   # Flash via Black Magic Probe
make flash-jlink # Flash via J-Link
```

### Testing Status

| Configuration | Flash | Debug | Stop/Detach | Notes |
|--------------|-------|-------|-------------|-------|
| ST-Link Run | ✅ | ✅ | ⚠️ | Toolbar remains open |
| ST-Link Attach | ✅ | ✅ | ⚠️ | Toolbar remains open |
| BMP Run | ✅ | ✅ | ⚠️ | UART on /dev/ttyACM1, toolbar remains open |
| BMP Attach | ✅ | ✅ | ⚠️ | Toolbar remains open |
| J-Link Run | ✅ | ✅ | ⚠️ | Requires SEGGER software, toolbar remains open |
| J-Link Attach | ✅ | ✅ | ⚠️ | Requires SEGGER software, toolbar remains open |

**Legend**: ✅ Tested and working | ❌ Not working | ⏳ Not yet tested | ⚠️ Works with cosmetic issue

**Known Issue**: The VS Code debug toolbar remains visible after Stop/Detach in all configurations. This is a cosmetic issue only - the debugger stops/detaches correctly and the target behaves as expected (Run mode: continues execution, Attach mode: continues execution). Simply close the toolbar manually or start a new debug session.

## Dependencies

- **ARM GCC toolchain** (`gcc-arm-none-eabi`) - Configure path in `Makefile`
- **Make** - Standard build system
- **VS Code** with recommended extensions
- **ST-Link tools** (`stlink-tools`) - For ST-Link flash and debug
- **Black Magic Probe** (optional) - Alternative debugger/programmer with built-in UART
- **J-Link** (optional) - SEGGER J-Link debugger with SEGGER Software Pack
- **bear** (optional) - For generating `compile_commands.json`

**Note**: The ARM toolchain does not need to be in your system PATH - it's configured directly in the Makefile.

## Troubleshooting

### Linker Script Issues
```bash
# Error: Multiple .ld files found
make clean
# Remove unwanted .ld files or specify manually:
make LINKER_SCRIPT=path/to/specific.ld
```

### Missing Dependencies
```bash
# Regenerate dependency files
make clean
make
```

### Language Server Issues
```bash
# Regenerate compile database
make clean
make compile_commands
# Restart VS Code
```