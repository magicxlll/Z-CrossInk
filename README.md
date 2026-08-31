# Z-CrossInk: Modular E-Ink Firmware & Community Plugin Engine

[![Fork of](https://img.shields.io/badge/Fork%20of-uxjulia%2FCrossInk%20v1.5.1-blue.svg)](https://github.com/uxjulia/CrossInk)
[![Target](https://img.shields.io/badge/Target-Xteink%20X3%20%2F%20X4-green.svg)](#supported-devices)
[![Z-Plugin Engine](https://img.shields.io/badge/Z--Plugin%20Engine-v1.0%20(KOReader--style)-orange.svg)](docs/Z_PLUGIN_SPEC.md)

**Z-CrossInk** is an extensible, modular firmware fork of [CrossInk](https://github.com/uxjulia/CrossInk) (v1.5.1) engineered specifically for **Xteink X3** and **Xteink X4** e-readers.

It empowers the e-ink community to run dynamic, user-installable plugins directly from the SD card (similar to KOReader plugins) without modifying the low-level hardware HAL or reflashing the device, while maintaining 100% effortless upstream synchronization with official CrossInk releases.

---

## Key Capabilities

### 1. KOReader-Style Dynamic Plugin Subsystem
- **Zero-Flash Plugin Installation**: Drop any plugin folder into `/sdcard/plugins/<plugin_id>/` (or `/.crosspoint/plugins/`). The system discovers and mounts plugins dynamically upon boot or live reload.
- **Embedded Lua 5.4 Mini Sandbox**: Safe, memory-capped (32KB heap allocation limit) embedded runtime with rich C++ bindings for E-ink drawing, physical button input, wireless HTTP fetching, file storage, and reader control.
- **Read the Plugin Spec**: [Z-Plugin Specification v1.0](docs/Z_PLUGIN_SPEC.md).

### 2. Built-in Flagship Plugin: Z-Truyen Pro
- **Direct Online Library Portal**: Browse curated Vietnamese novel categories, search with accent-stripping virtual keyboard, and download directly over Wi-Fi.
- **Bi-directional KOReader Sync (KOSync)**: Automatically syncs reading progress, last-read chapter, and reading statistics between your X3 e-reader and the Z-Truyen Android application.

### 3. Non-Invasive Architecture & Zero-Brick Protection
- **Hardware Isolation**: Core HAL (`freeink-sdk/libs/hardware/*`), ESP-IDF bootloader, and partition tables remain completely untouched.
- **Safe Boot Recovery Guard (`ZSafeBootGuard`)**:
  - Hold the physical **Back** button during power-on wake to instantly bypass all SD card plugins and boot in pure Safe Mode.
  - Automatic recovery kicks in if 3 consecutive abnormal reboots are detected in RTC memory.

### 4. 100% Upstream Git Synchronization
Keep your fork completely synchronized with new CrossInk upstream releases (e.g. `v1.5.2`, `v1.6.0`) with a single command:
```bash
./scripts/z_sync_upstream.sh release/v1.6.0
```

---

## Directory Structure

```text
Z-CrossInk/
├── docs/
│   ├── Z_PLUGIN_SPEC.md            # Community Plugin Specification & Lua API
│   └── ...                         # Upstream documentation
├── include/
│   └── z_core/                     # Global Z-CrossInk configuration & toggles
├── lib/
│   └── z_lua/                      # Featherweight embedded Lua 5.4 runtime
├── plugins/
│   └── ztruyen/                    # Flagship Z-Truyen reference plugin
│       ├── manifest.json
│       └── main.lua
├── scripts/
│   ├── build_z_crossink.sh         # Automated compilation & packaging
│   └── z_sync_upstream.sh          # 1-Click upstream sync tool
└── src/
    ├── z_core/                     # Safe boot guard & KOSync engine
    ├── plugins/                    # Dynamic plugin host & manifest parser
    └── ...                         # Core CrossInk activities & renderer
```

---

## Creating Your First Plugin in 5 Minutes

Create a folder on your SD card: `/sdcard/plugins/my_plugin/`

1. **`manifest.json`**:
```json
{
  "id": "my_plugin",
  "name": "My Custom Widget",
  "version": "1.0.0",
  "author": "YourName",
  "category": "HOME_APP",
  "entry": "main.lua",
  "enabled": true
}
```

2. **`main.lua`**:
```lua
function onEnter()
    ZInk.Display.clear()
    ZInk.Display.drawText(30, 50, "Hello from Z-CrossInk Plugin!", "BOLD", 16)
    ZInk.Display.refresh(false)
end

function onInput(key, eventType)
    if key == "BACK" and eventType == "RELEASE" then
        ZInk.UI.popView()
        return true
    end
    return false
end
```

---

## Building Firmware

```bash
# Build firmware binary & package default plugins:
./scripts/build_z_crossink.sh
```

---

## License

This project is licensed under the terms of the [MIT License](LICENSE), matching upstream CrossInk.
