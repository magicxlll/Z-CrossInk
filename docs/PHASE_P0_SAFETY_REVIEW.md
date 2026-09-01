# PHASE P0 — HARDWARE SAFETY & RECOVERY BOUNDARY REVIEW

**Device Target:** Xteink X3 (ESP32-C3 RISC-V SoC, International Unlocked Edition)  
**Safety Mandate:** Zero Uncontrolled Hardware Intervention, Bounded Risk & Proven Recovery  
**Date:** 2026-09-01  

---

## 1. Hardware Safety Boundary Verification

The audit confirms that Z-CrossInk treats all low-level hardware systems as **strictly read-only protected infrastructure**:

| Hardware Subsystem | Access Status | Verification Result |
| :--- | :--- | :--- |
| **Bootloader (`bootloader.bin`)** | **Untouched** | Standard ESP-IDF 2nd stage bootloader preserved. |
| **Partition Layout (`partitions.csv`)** | **Untouched** | Uses default CrossInk OTA layout (`app0`, `app1`, `nvs`, `otadata`). |
| **EFuses / Cryptographic Engine** | **Untouched** | No eFuse modification commands or keys altered. |
| **OTA Switching Logic** | **Standard** | Relies solely on native ESP-IDF `esp_ota_set_boot_partition`. |
| **FreeInk-SDK Hardware Drivers** | **Untouched** | Panel waveforms, GPIO registers, and SPI timings preserved 100%. |
| **Power Management Core** | **Standard** | Uses CrossInk native `PowerManager` for deep sleep and wake-up. |

---

## 2. Emergency Recovery Path (CrossPoint Escape Hatch)

1. **Recovery Protocol:**
   - The device retains full compatibility with **CrossPoint Escape Hatch** recovery SD card.
   - If an OTA firmware slot encounters any persistent issue, Escape Hatch boots independently from the secondary partition, flashes a known-good firmware binary (`known-good-crossink.bin` or `z-crossink-x3-v1.5.1.bin`) into the inactive partition, switches `otadata`, and reboots safely.
2. **Flash Dump Backup Procedure:**
   - The tool `scripts/x3_backup_flash_tool.sh` provides 1-click ROM dumps via `esptool.py` to archive `GOLDEN_STOCK_FULLFLASH.bin` (full 4MB/8MB dump) before any physical device flashing.

---

## 3. Plugin Containment Guarantee

- Plugins run exclusively inside the `ZLuaEngine` virtual machine.
- Direct C pointer access, raw heap access, and hardware interrupt manipulation are physically impossible from Lua scripts.
- Any syntax error, memory limit exceedance, or runtime fault inside a plugin is trapped by `ZLuaActivity` and handled gracefully by displaying a visual error screen, allowing the user to press `BACK` to return to the Home menu without restarting the device.
