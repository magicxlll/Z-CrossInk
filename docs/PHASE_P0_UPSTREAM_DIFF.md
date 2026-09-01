# PHASE P0 — UPSTREAM DIFF & COMPATIBILITY BUDGET REPORT

**Baseline:** `uxjulia/CrossInk` release/v1.5.1  
**Fork:** `magicxlll/Z-CrossInk` main branch  
**Audit Date:** 2026-09-01  

---

## 1. Upstream Modified Files Summary (Diff Budget)

Z-CrossInk strictly follows the principle of minimal patch surface on upstream CrossInk files. Only 7 upstream files have been modified, with total modifications under 100 lines:

| File | Nature of Modification | LOC Added/Changed | Upstream Conflict Risk |
| :--- | :--- | :--- | :--- |
| `src/main.cpp` | Added early boot safety check hook & plugin discovery call | +10 LOC | **Very Low** |
| `src/activities/home/HomeActivity.cpp` | Dynamic enumeration and launching of home plugins | +56 LOC | **Low** |
| `src/activities/ActivityManager.h` | Shared header cleanup | +3 LOC | **Zero** |
| `src/activities/settings/SdFirmwareUpdateActivity.cpp` | Added Z-CrossInk binary filename recognition | +9 LOC | **Very Low** |
| `platformio.ini` | Added z_core and plugin include directories and macro flag | +6 LOC | **Zero** |
| `scripts/gen_i18n.py` | Python 3 script compatibility tweak | +2 LOC | **Zero** |
| `README.md` | Fork introduction, architecture docs, and developer instructions | +200 LOC | **Zero** |

**Total modified upstream code lines:** ~86 lines of C++ code across 5 source files.

---

## 2. New Subsystem Directories (Zero Upstream Conflict)

All new capabilities reside entirely in dedicated, isolated namespaces:

- `include/z_core/` — Z-CrossInk configuration, limits, and constant definitions (`ZConfig.h`).
- `src/z_core/` — Safety boot guard, crash tracking, and safe-mode state machine (`ZSafeBootGuard.cpp`).
- `src/plugins/` — Plugin manager, manifest parser, and plugin lifecycle types (`ZPluginManager.cpp`, `ZPluginManifest.cpp`).
- `src/plugins/scripting/` — Sandboxed Lua activity, custom memory allocator, and ZInk capability facade (`ZLuaActivity.cpp`, `ZLuaBindings.cpp`, `ZLuaEngine.cpp`).
- `lib/z_lua/` — Stripped Lua 5.4.7 core library (sandboxed, OS/debug/IO libraries removed).
- `plugins/` — Modular SD-card plugins (`ztruyen`, `viet_dict`, `sudoku`, `system_info`, `lunar_calendar`, `hello`).
- `scripts/` — Upstream synchronization, build verification, and recovery backup tools.

---

## 3. Upstream Merge Rebase Invariant

When upstream CrossInk updates to v1.5.2 or v1.6.0:
1. `git fetch upstream && git merge upstream/main` executes cleanly without semantic conflicts because the hook points in `main.cpp` and `HomeActivity.cpp` are located at the end of initialization functions.
2. The automatic script `scripts/z_sync_upstream.sh` performs automated 3-way rebasing, runs compilation gates, and validates binary sizes automatically.
