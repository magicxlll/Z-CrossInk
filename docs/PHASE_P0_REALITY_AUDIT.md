# PHASE P0 — REPOSITORY REALITY AUDIT REPORT

**Project:** Z-CrossInk (Fork of `uxjulia/CrossInk` v1.5.1)  
**Target:** Xteink X3 (ESP32-C3, 528x792 E-ink Display)  
**Audit Date:** 2026-09-01  
**Auditor:** Antigravity AI Engineer  
**Status:** **PHASE P0 AUDIT PASSED**

---

## 1. System Inventory & Baseline Classification

Every feature defined in `Z-CrossInk_Master_Engineering_Safety_And_Plugin_Spec_V1.md` is classified below:

| Feature / Subsystem | Status | Implementation Location | Notes |
| :--- | :--- | :--- | :--- |
| **Upstream Git Remote Tracking** | **EXISTING** | `.git/config` (`origin`, `upstream`) | Branch `main` tracking `upstream/release/v1.5.1` & `upstream/main` |
| **Non-invasive Main Hook** | **EXISTING** | `src/main.cpp:L25-L35` | Boot guard and plugin discovery hooks cleanly encapsulated |
| **ActivityManager Integration** | **EXISTING** | `src/activities/home/HomeActivity.cpp` | Dynamic Home menu listing and activity push/pop |
| **Embedded Lua Engine** | **EXISTING** | `lib/z_lua/`, `src/plugins/scripting/` | Full Lua 5.4.7 stripped sandbox with custom memory allocator |
| **Memory Quota Enforcement** | **EXISTING** | `ZConfig.h`, `ZLuaEngine.cpp` | 1MB cap for Desktop Simulator, 96KB cap for ESP32-C3 hardware |
| **Manifest Parsing** | **EXISTING** | `src/plugins/ZPluginManifest.cpp` | JSON parser with strict field extraction |
| **Path Traversal Protection** | **PARTIAL** | `src/plugins/ZPluginManifest.cpp` | Needs canonical path checking for sub-assets and storage API |
| **Permission Check Enforcement** | **PARTIAL** | `src/plugins/scripting/ZLuaBindings.cpp` | Declared in manifest; needs runtime enforcement gate |
| **Crash Guard / Safe Mode** | **EXISTING** | `src/z_core/ZSafeBootGuard.cpp` | Safe mode flag detection on SD card with automatic fallback |
| **Two-Stage Launch Confirmation** | **PROPOSED** | Section 19.2 of Master Spec | To be implemented in Phase P2 |
| **ZInk.Display Facade** | **EXISTING** | `ZLuaBindings.cpp` | Framebuffer primitives + `displayBuffer` sync |
| **ZInk.Input Facade** | **EXISTING** | `ZLuaBindings.cpp`, `ZLuaActivity.cpp` | UP, DOWN, LEFT, RIGHT, CONFIRM, BACK event mapping |
| **ZInk.Storage Facade** | **EXISTING** | `ZLuaBindings.cpp` | Read, write, exists mapped through `HalStorage` |
| **ZInk.Reader Facade** | **EXISTING** | `ZLuaBindings.cpp` | Direct handoff to native `ReaderActivity` |
| **ZInk.System Facade** | **EXISTING** | `ZLuaBindings.cpp` | Battery %, Voltage, Free Heap, Uptime |
| **ZInk.Http Facade** | **PARTIAL** | `ZLuaBindings.cpp` | HTTP GET / POST bindings implemented; streaming to be added |
| **Z-Truyen Flagship Plugin** | **EXISTING** | `plugins/ztruyen/` | Multi-screen portal with offline books and KOSync UI |
| **Community Plugins** | **EXISTING** | `plugins/` | Sudoku, Lunar Calendar, System Info, Viet Dict |
| **Hardware Core Alterations** | **SAFE (NONE)** | Bootloader, Partitions, HAL | 0% modification to bootloader, partition table, or EPD drivers |

---

## 2. Lua Runtime Engine Audit

1. **Engine Version:** Lua 5.4.7 (C89/C99 portable source in `lib/z_lua/`).
2. **Library Sandboxing:**
   - Enabled standard libraries: `_G` (safe builtins), `table`, `string`, `math`, `utf8`.
   - Disabled dangerous libraries: `os` (process execution/system calls), `io` (unrestricted raw POSIX file handles), `debug` (stack inspection/bytecode manipulation), `package` (arbitrary dynamic C shared object loading).
3. **Memory Safety:**
   - Integrated custom allocator `ZLuaEngine::customAlloc` intercepts all `realloc`/`malloc` requests.
   - Throws immediate memory ceiling error if memory exceeds `MAX_PLUGIN_HEAP_BYTES` without fragmenting or crashing ESP-IDF free heap.

---

## 3. Directory Layout and SD Path Behavior

- **Canonical User Plugin Path:** `/plugins/<plugin_id>/manifest.json` and `main.lua`.
- **Primary System Plugin Path:** `/.crosspoint/plugins/<plugin_id>/`.
- **Plugin Discovery Engine:** Iterates both paths on boot, parsing valid manifests and attaching `ZLuaPlugin` instances into `ZPluginManager`.

---

## 4. Hardware Safety Gate Verification

- **Bootloader (`bootloader.bin`):** UNTOUCHED.
- **Partition Table (`partitions.csv`):** UNTOUCHED (Factory + OTA_0 + OTA_1 + NVS + VFS intact).
- **FreeInk SDK / EPD Controller (`freeink-sdk`):** UNTOUCHED.
- **OTA Data Partition (`otadata`):** UNTOUCHED, 100% compatible with CrossPoint Escape Hatch emergency rollback tool.

---

## 5. P0 Audit Sign-off

The repository architecture matches 100% of the non-invasive fork requirements defined in the Master Engineering Specification. Ready to proceed with Phase P1 and Phase P2 enhancements.
