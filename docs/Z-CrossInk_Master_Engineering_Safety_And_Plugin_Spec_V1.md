# Z-CrossInk — Master Engineering, Safety, Upstream-Sync & Plugin Platform Specification

**Project:** Z-CrossInk  
**Base:** `uxjulia/CrossInk`  
**Owner fork:** `magicxlll/Z-CrossInk`  
**Target device:** Xteink X3 International, USB-unlocked  
**Primary user goal:** Z-Truyen deeply integrated into the X3 firmware while preserving a low-risk path to upstream updates and enabling SD-card-installable plugins without reflashing firmware.  
**Document type:** authoritative implementation and safety specification for an AI coding agent  
**Status:** Engineering baseline / implementation gate  
**Version:** 1.0

---

## 0. Executive decision

Z-CrossInk is **not** a new firmware written independently of CrossInk. It is a **small, maintainable feature layer on top of CrossInk**, with strict boundaries around hardware/boot/recovery code.

The project has four simultaneous objectives:

1. Keep tracking upstream CrossInk with a small, auditable diff.
2. Add a runtime plugin facility so a plugin such as Z-Truyen can be installed from SD without reflashing the firmware.
3. Keep hardware-facing modifications to the absolute minimum.
4. Prove the system on a real Xteink X3 without taking unnecessary brick risk.

The core product architecture SHALL be:

```text
                     Z-CROSSINK FIRMWARE
┌───────────────────────────────────────────────────────────────┐
│                       UPSTREAM CROSSINK                      │
│                                                               │
│  Boot / Power / HAL / Display / Storage / Reader / Network  │
│                                                               │
├──────────────────────── Z-CrossInk Layer ────────────────────┤
│                                                               │
│  Plugin Manager                                               │
│       │                                                       │
│       ├── Manifest / permissions                              │
│       ├── Safe loader                                         │
│       ├── Activity adapter                                    │
│       ├── Crash guard                                         │
│       └── Plugin API facade                                   │
│                    │                                          │
│               Runtime VM                                     │
│                    │                                          │
│              SD-card plugin                                  │
│                    │                                          │
│              Z-Truyen plugin                                 │
│                                                               │
└───────────────────────────────────────────────────────────────┘
                         │
                         ▼
                   Xteink X3 hardware
```

**The Z-CrossInk layer must behave as an add-on. It must not replace or fork the upstream hardware architecture.**

CrossInk itself is an activity-driven ESP32-C3 firmware with persistent settings/state, SD-first caching, E-Ink rendering, reader flows and network/web-server flows. The upstream architecture explicitly identifies `src/main.cpp`, `ActivityManager`, `lib/hal`, `lib/Epub`, `freeink-sdk`, and network activities as the main integration surfaces. citeturn343181search0turn447608search0

---

# 1. Important source-reality rule

The repository `magicxlll/Z-CrossInk` could not be fetched directly in this environment at the time this specification was prepared because GitHub returned a cache miss / direct clone was unavailable. Therefore this document **does not claim that every current Z-CrossInk source file has been inspected line-by-line**.

The specification is grounded in:

- the CrossInk upstream source and current architecture documentation;
- the CrossPoint upstream/recovery tooling;
- the two previously supplied Z-Plugin design documents;
- the project's stated current milestone: plugin UI loads in the X3 simulator;
- the X3 hardware and recovery observations already established in this project.

Where this document says **PROPOSED**, the AI agent must verify the current Z-CrossInk implementation before coding. It must not treat a proposed API as an existing API.

**Hard rule:** source code wins over this document when the two disagree. The agent must stop and record a discrepancy rather than inventing an implementation.

---

# 2. What Z-CrossInk is and is not

## 2.1 It is

A controlled fork of CrossInk that adds:

- a dynamic plugin manager;
- a sandboxed lightweight scripting runtime;
- a small plugin ABI/API;
- plugin activities that integrate with the existing CrossInk `ActivityManager`;
- plugin installation from SD;
- optional plugin enable/disable;
- plugin crash containment and recovery;
- Z-Truyen as the first heavy plugin;
- compatibility with the existing CrossInk reader and network stack.

## 2.2 It is not

It must not become:

- a new operating system;
- a new bootloader;
- a new partition scheme;
- a replacement for `freeink-sdk`;
- an alternative E-Ink display stack;
- a second independent reader engine;
- a second network stack;
- an unrestricted scripting environment with raw C/C++ access;
- an automatic firmware updater that can overwrite bootloader/partition data.

---

# 3. Current technical baseline

CrossInk upstream currently targets Xteink X3/X4 and Seeed Sticky on ESP32-C3 and uses PlatformIO. Its documented runtime is activity-driven, with storage/state, E-Ink renderer, EPUB parser/layout, network/web-server activities, and SD-first cache. citeturn343181search0

CrossInk's repository currently presents itself as a personal fork of CrossPoint Reader focused on fonts and reading statistics. citeturn447608search0

The repository has an upstream submodule relationship to `freeink-sdk`; changes in the SDK should be synchronized by explicit submodule bumps rather than by replacing the SDK wholesale. citeturn343181search0

CrossPoint's recovery ecosystem provides important safety tooling. Escape Hatch can boot, inspect X3/X4, flash a firmware image into the inactive OTA partition, switch `otadata`, and boot the other OTA slot. It intentionally does not replace the bootloader. citeturn423445search0turn423445search1

---

# 4. Primary engineering principle: keep the patch surface small

The fork must follow this architecture rule:

```text
UPSTREAM CROSSINK
      │
      │ minimal seams
      ▼
Z-CROSSINK EXTENSION LAYER
      │
      ├── PluginManager
      ├── PluginActivity
      ├── PluginRuntime
      ├── PluginPermissions
      ├── PluginCrashGuard
      └── ZInk API Facade
```

The agent MUST NOT modify unrelated upstream files just to make the feature easier to implement.

Preferred implementation sequence:

1. add new files under a dedicated Z-CrossInk namespace/path;
2. add the smallest possible hook into existing activity/runtime code;
3. add tests;
4. keep upstream changes mechanically easy to rebase;
5. document every upstream-touching file.

---

# 5. Upstream synchronization strategy

This is a first-class requirement, not a convenience.

## 5.1 Remote layout

The Git repository MUST use:

```text
origin   = https://github.com/magicxlll/Z-CrossInk.git
upstream = https://github.com/uxjulia/CrossInk.git
```

Recommended branches:

```text
upstream-main       mirror/reference of CrossInk main
zci-main            Z-CrossInk release branch
feature/*           isolated Z-CrossInk work
release/*            release preparation
```

The agent MUST NOT develop directly on `zci-main` for feature work.

## 5.2 Synchronization procedure

At every upstream sync:

```text
fetch upstream
   ↓
create upstream sync branch
   ↓
merge/rebase upstream changes
   ↓
run conflict audit
   ↓
run complete simulator tests
   ↓
run plugin tests
   ↓
run firmware size gate
   ↓
human review
   ↓
merge into zci-main
```

Recommended git commands:

```bash
git fetch upstream --tags
git checkout -b sync/upstream-YYYYMMDD upstream/main
git merge zci-main
```

The exact merge strategy may be changed by the maintainer, but **every upstream synchronization must preserve a machine-readable record of the upstream commit and the resulting Z-CrossInk commit**.

## 5.3 Diff budget

The project SHOULD maintain a measurable patch budget:

```text
UPSTREAM MODIFICATIONS:
- main.cpp: minimal hook
- ActivityManager seam: minimal
- plugin runtime files: new
- plugin SDK files: new
- Z-Truyen files: new
```

No large rewrite of upstream files is acceptable unless explicitly approved.

The CI pipeline SHOULD generate:

```text
reports/upstream-diff.txt
reports/upstream-diff-stat.txt
```

and fail or require manual review if the number of modified upstream lines grows unexpectedly.

## 5.4 Version provenance

Every Z-CrossInk firmware build MUST expose:

```text
Z-CrossInk version
Z-CrossInk git SHA
CrossInk upstream SHA
freeink-sdk SHA
build timestamp
build target
```

The same information must be stored in a generated `build-manifest.json` artifact.

---

# 6. Hardware safety boundary — NON-NEGOTIABLE

Z-CrossInk MUST treat the following as protected infrastructure:

```text
BOOTLOADER
PARTITION TABLE
OTA DATA FORMAT
FLASH ENCRYPTION / SECURE BOOT
EFUSES
LOW-LEVEL FLASH WRITE ROUTINES
EPD HARDWARE INITIALIZATION
GPIO HARDWARE DEFINITIONS
POWER MANAGEMENT CORE
```

The plugin system MUST NOT have access to these components.

## 6.1 Forbidden plugin capabilities

The plugin ABI MUST NOT expose:

```text
raw pointer access
memory address access
ESP-IDF APIs
FreeRTOS task creation
raw GPIO
SPI
I2C
ADC
flash erase
flash write
bootloader control
OTA selector control
partition erase/write
EFuse write
```

No plugin may include:

```cpp
#include <esp_system.h>
#include <esp_partition.h>
#include <esp_flash.h>
```

unless the code is part of the trusted Z-CrossInk native core rather than a plugin.

## 6.2 Hardware modification policy

The preferred Z-CrossInk feature implementation is:

```text
Application layer only
        ↓
existing CrossInk HAL
        ↓
existing freeink-sdk
        ↓
hardware
```

The agent must NOT modify the display driver, partition table, bootloader, or hardware detection merely to implement plugins.

If a future feature genuinely requires a hardware-layer change, it becomes a separate high-risk engineering project and requires human approval before implementation.

---

# 7. “Zero-brick” terminology correction

The project MUST NOT claim:

> Zero-Brick Guarantee

The correct terminology is:

> **Bounded Risk + Safe Recovery Design**

A plugin sandbox can reduce risk; it cannot mathematically guarantee that an application-level bug cannot crash or corrupt the main firmware process.

The hardware recovery model must rely on:

1. untouched bootloader;
2. valid OTA structure;
3. backup of known-good firmware;
4. Escape Hatch / SD recovery where validated;
5. physical-test gates;
6. plugin crash disable mechanism.

Escape Hatch itself documents that it is an application-level recovery path and that truly unconditional recovery would require bootloader changes, which it deliberately avoids. citeturn423445search0turn423445search1

---

# 8. Plugin platform: reality-first architecture

The supplied Z-Plugin documents describe a Lua plugin system with `manifest.json`, `main.lua`, `ZInk.*` APIs, a 32 KB heap cap and safe mode. fileciteturn0file0L9-L33

They also describe SD installation and plugin lifecycle callbacks. fileciteturn0file1L10-L12

Those are **product requirements / proposed APIs**, not assumptions that CrossInk already provides them.

The actual CrossInk upstream runtime is Activity-driven. It already has `ActivityManager`, screen-level activities, reader/network/home/settings activities, and a main application loop. citeturn343181search0

Therefore the plugin system MUST be implemented as:

```text
CrossInk Activity architecture
            │
       PluginActivity
            │
       PluginManager
            │
      Script runtime
            │
       ZInk facade
```

not as a parallel application framework.

---

# 9. Plugin directory specification

Canonical consumer plugin location:

```text
/plugins/<plugin_id>/
```

For system-private plugin metadata/cache, use:

```text
/.zcrossink/
```

Do not assume `/.crosspoint/plugins/` is writable through CrossPoint network upload; CrossPoint protects dot-directories in its web server. Z-CrossInk should therefore use normal SD paths for user-installed plugins and reserve dot-directories for firmware-owned state.

Recommended structure:

```text
/plugins/
  ztruyen/
    manifest.json
    main.lua
    icon.bmp
    assets/
      ...

  example_hello/
    manifest.json
    main.lua
```

---

# 10. Manifest specification

Required fields:

```json
{
  "id": "ztruyen",
  "name": "Z-Truyen",
  "version": "0.1.0",
  "entry": "main.lua",
  "category": "HOME_APP",
  "minZCrossInkVersion": "0.1.0",
  "permissions": [
    "display",
    "input",
    "storage",
    "network",
    "reader"
  ],
  "enabled": true
}
```

Mandatory validation:

- UTF-8 JSON;
- valid semantic version;
- ID `[a-z0-9_]+`;
- entry file exists;
- plugin path remains inside `/plugins/<plugin_id>/`;
- no `..` traversal;
- requested permissions are known;
- plugin size limits are enforced;
- optional checksum/signature fields may be added later.

The agent MUST reject unknown privileged permissions rather than silently granting them.

---

# 11. Plugin runtime choice

## 11.1 Preferred MVP

Use a **small embedded Lua runtime** only if the runtime can be built deterministically for ESP32-C3 and integrated without destabilizing the firmware.

The runtime MUST be compiled as a restricted configuration:

- no shell/process execution;
- no arbitrary file IO outside ZInk Storage API;
- no package manager;
- no `os` library;
- no `io` library exposing raw filesystem handles;
- no `debug` library;
- no FFI;
- no dynamic native library loading;
- no direct C function pointer exposure.

The runtime version must be pinned and recorded.

## 11.2 Important memory decision

The supplied design claims a 32 KB plugin heap. fileciteturn0file0L29-L33

This is a **starting target, not a validated fact**.

The agent must benchmark actual memory usage on both:

```text
simulator
X3 real hardware
```

The runtime MUST NOT be declared safe merely because the allocator has a 32 KB logical cap.

## 11.3 Z-Truyen should not be Lua-only

Z-Truyen is heavier than a simple clock or dictionary plugin.

The intended architecture is:

```text
Lua plugin
  ├── UI
  ├── state
  ├── user input
  └── orchestration

Trusted native ZTruyenCore
  ├── HTTP/TLS
  ├── streaming parser
  ├── source adapters
  ├── EPUB builder
  ├── image normalization
  └── cache
```

The heavy native engine MUST be a normal application library inside Z-CrossInk, not arbitrary native code supplied by an SD-card plugin.

This preserves most of the safety benefits of the plugin model while still allowing Z-Truyen to use the ESP32-C3 efficiently.

---

# 12. ZInk API contract

The previously supplied specification defines the conceptual API groups:

```text
ZInk.Display
ZInk.Input
ZInk.Http
ZInk.Storage
ZInk.Reader
ZInk.System
ZInk.UI
```

See the supplied API specification for the intended semantics. fileciteturn0file0L146-L200

In Z-CrossInk, these APIs MUST be implemented as a **capability facade**, not direct hardware bindings.

Example:

```text
Lua
 ↓
ZInk.Display.refresh()
 ↓
Permission check
 ↓
Validated native call
 ↓
existing CrossInk renderer/HAL
```

---

# 13. Reader integration

The proposed:

```text
ZInk.Reader.openBook(path)
```

must map to the existing CrossInk reader/activity architecture rather than launching a second reader engine. CrossInk already routes EPUB/XTC/TXT through `ReaderActivity` and uses SD-backed layout/cache. citeturn343181search0

Required behavior:

```text
Plugin
  ↓
request reader open
  ↓
validate path
  ↓
ensure file exists and is readable
  ↓
ActivityManager start ReaderActivity
  ↓
existing EPUB reader
```

No plugin gets direct access to reader internals.

---

# 14. E-Ink rendering integration

Plugins MUST reuse the existing CrossInk rendering and refresh pipeline.

A plugin must not invent a second framebuffer implementation.

The plugin API may expose high-level operations such as:

```text
clear()
drawText()
drawRect()
drawLine()
drawBitmap()
requestRefresh(mode)
```

but `requestRefresh()` must eventually map to the existing renderer/refresh policy.

Plugin code must never directly toggle panel GPIO or EPD controller commands.

---

# 15. Input integration

Physical input is routed by the existing CrossInk activity manager.

The plugin system must receive normalized events:

```text
UP
DOWN
LEFT
RIGHT
CONFIRM
BACK
POWER
```

The plugin does not read raw ADC values.

A plugin can request an event be consumed, but it must not permanently capture global input.

---

# 16. Network API integration

For normal plugins:

```text
ZInk.Http.get()
ZInk.Http.post()
ZInk.Http.download()
```

must enforce:

- HTTPS/HTTP policy;
- connection timeout;
- response size limits;
- operation timeout;
- cancellation;
- maximum concurrent requests;
- heap-safe streaming.

For Z-Truyen, network requests SHOULD be implemented in the native `ZTruyenCore`, because HTML parsing and EPUB generation are substantially heavier than a simple JSON weather request.

---

# 17. Storage security

All plugin paths MUST be canonicalized before use.

Forbidden:

```text
/../
..\
absolute path outside SD
bootloader.bin
partition table path
raw flash path
```

The plugin storage facade MUST restrict write operations to:

```text
/plugins/<plugin_id>/
/.zcrossink/plugin-data/<plugin_id>/
/Books/   (only through a separate book-storage capability)
```

The plugin must not write directly to:

```text
/.crosspoint/
```

unless the specific API contract explicitly permits one documented file path.

---

# 18. Plugin lifecycle

Preferred lifecycle:

```text
DISABLED
   ↓
DISCOVERED
   ↓
VALIDATING
   ↓
LOADED
   ↓
ENTERED
   ↓
RUNNING
   ↓
EXITING
   ↓
UNLOADED
```

Callbacks MAY include:

```lua
onInit()
onEnter()
onRender()
onInput(button, action)
onExit()
```

These callback names come from the supplied plugin design. fileciteturn0file1L118-L154

The exact dispatch mechanism must map to CrossInk's ActivityManager instead of creating a second global event loop.

---

# 19. Crash containment and Safe Mode

## 19.1 Required behavior

Plugin crashes must not automatically disable the entire firmware.

Maintain per-plugin state:

```text
launch_count
launch_pending
last_launch_time
stable_confirmation
crash_count
last_error
```

## 19.2 Two-stage launch confirmation

On plugin start:

```text
mark launch_pending = true
load plugin
run plugin
```

After a defined stability window or explicit successful initialization:

```text
launch_pending = false
crash_count = 0
```

If reboot occurs while `launch_pending == true`:

```text
crash_count++
```

After threshold:

```text
plugin disabled
enter safe mode
```

## 19.3 Safe Mode

Safe Mode must provide:

```text
boot CrossInk core
plugins disabled
user can remove/disable plugin
```

The implementation MUST use the existing boot/recovery architecture wherever possible and must not introduce a second bootloader.

The supplied design proposes disabling external plugins after repeated crashes. fileciteturn0file1L62-L65

That behavior is adopted as a product goal, but its actual reliability must be proven in simulator and real hardware.

---

# 20. Boot safety and upstream recovery integration

CrossPoint's Escape Hatch is a critical recovery asset. It can flash a firmware into the inactive OTA slot and boot the other slot, while deliberately leaving the second-stage bootloader untouched. citeturn423445search0turn423445search1

Z-CrossInk must preserve this recovery model.

## 20.1 First physical release rules

Before first physical Z-CrossInk flash:

```text
GOLDEN_STOCK_FULLFLASH.bin
GOLDEN_CURRENT_KNOWNGOOD.bin
SHA256 for both
SD backup
known recovery SD
Escape Hatch validated
```

## 20.2 No partition redesign for plugin support

Plugins live on SD. The plugin architecture MUST NOT require:

- a new flash partition;
- new OTA partition;
- new bootloader;
- filesystem partition resizing.

If firmware size becomes too large for the current application slot, **stop** and redesign the feature. Do not repartition merely to fit the plugin system without explicit approval.

---

# 21. Firmware size budget

Because the X3 uses constrained ESP32-C3 resources and CrossInk already relies heavily on SD-first caching to limit RAM use, the plugin runtime must have a strict size budget. CrossInk documents constrained RAM as a central architectural constraint. citeturn343181search0

CI must record:

```text
firmware binary size
text
rodata
data
bss
free heap at boot
free heap at home
free heap inside plugin
largest allocation
```

Suggested initial gates:

```text
No unexplained >5% firmware size increase per feature phase.
No new boot-time heap regression >10 KB without review.
No persistent heap leak after plugin unload.
```

These are engineering gates and may be tightened after measurements.

---

# 22. Z-Truyen plugin architecture

Z-Truyen must be the flagship plugin, but it must not be allowed to dictate the entire plugin API.

Recommended structure:

```text
/plugins/ztruyen/
    manifest.json
    main.lua
    assets/

ZTruyenCore (trusted native library)
    SourceRegistry
    SearchEngine
    BookModel
    ChapterModel
    HTTP client
    streaming parser
    content normalizer
    EPUB builder
    image processor
    cache manager
```

## 22.1 Direct mode

The primary long-term goal is:

```text
X3
 ↓ Wi-Fi
web source
```

without a mandatory external server.

## 22.2 Server mode

The same plugin may optionally use:

```text
X3
 ↓
OPDS/API
 ↓
phone/Mac/cloud
```

for difficult sources, caching, or richer server-side scraping.

This keeps the project's earlier Mobile Edge / cloud work useful without making it mandatory.

---

# 23. Z-Truyen source adapter capability model

Every source MUST declare:

```json
{
  "id": "example",
  "direct": true,
  "server": true,
  "requiresJavaScript": false,
  "requiresLargeParser": false,
  "supportsImages": true
}
```

The X3 client can then decide:

```text
DIRECT
SERVER
UNSUPPORTED
```

This prevents a complex website from causing a firmware crash simply because it exceeds the capabilities of the embedded parser.

---

# 24. Z-Truyen memory strategy

Never load a complete chapter into one large RAM string if it can be avoided.

Preferred pipeline:

```text
HTTP stream
    ↓ chunks
stream parser
    ↓
normalized fragments
    ↓
SD temp/cache
    ↓
EPUB writer
    ↓
final EPUB
```

The X3's existing reader already follows an SD-first philosophy for expensive EPUB parsing/layout data. Z-Truyen should follow the same philosophy. citeturn343181search0

---

# 25. Plugin installation UX

The consumer experience should be:

```text
1. Copy plugin ZIP/folder to SD
2. Boot X3
3. Z-CrossInk scans plugin directory
4. Validate manifest
5. Show plugin in Home Apps / Plugin Manager
6. User selects Install/Enable
```

Optional future experience:

```text
Z-Truyen Android app
       ↓ Wi-Fi
X3 file transfer
       ↓
/plugins/<plugin_id>/
```

The agent MUST NOT implement an auto-install mechanism that writes arbitrary binary firmware artifacts.

---

# 26. Plugin update model

A plugin update MUST NOT require firmware flashing.

Flow:

```text
new plugin package
   ↓
validate manifest
   ↓
verify checksum/signature if enabled
   ↓
stage into temporary directory
   ↓
validate files
   ↓
atomic rename into plugin directory
   ↓
mark version active
```

Never overwrite the only copy in place.

Keep:

```text
/plugins/.staging/
```

outside the user-visible plugin list.

---

# 27. Plugin signature roadmap

V1 may use checksums and trusted package provenance.

V2 SHOULD support:

```text
manifest
plugin archive
SHA-256
optional Ed25519 signature
```

Because arbitrary Lua code from an SD card is a trust boundary, signature verification is a long-term requirement for a community plugin marketplace.

---

# 28. Simulator-first development plan

The current project already reports that plugin UI layers can be entered in the X3 simulator. Treat this as **bootstrap evidence, not final validation**.

## Phase P0 — Repository reality audit

Tasks:

1. checkout exact Z-CrossInk commit;
2. inspect current modified files relative to CrossInk;
3. identify the existing plugin UI code;
4. identify whether Lua is actually embedded;
5. identify current plugin manager;
6. identify actual manifest parser;
7. identify actual plugin lifecycle;
8. identify exact C++/Lua bridge;
9. identify current safe-mode implementation;
10. identify every upstream file modified by Z-CrossInk.

Deliverables:

```text
reports/P0_REALITY_AUDIT.md
reports/P0_UPSTREAM_DIFF.md
reports/P0_PLUGIN_STATUS.md
```

**P0 MUST PASS before further architecture changes.**

---

# 29. Phase P1 — Minimal Hello Plugin

Create only:

```text
/plugins/hello/
  manifest.json
  main.lua
```

Functionality:

- load;
- display one screen;
- respond to UP/DOWN/CONFIRM/BACK;
- exit cleanly;
- unload cleanly.

No network.

No EPUB.

No background task.

No custom native code.

Pass criteria:

```text
100 launches
100 exits
0 crashes
0 persistent heap loss
```

---

# 30. Phase P2 — Plugin Safety Layer

Implement:

- manifest validation;
- permission checks;
- path sandbox;
- runtime memory accounting;
- callback timeout policy;
- crash counter;
- safe mode.

Test intentionally broken plugins:

```text
infinite loop
invalid API call
bad JSON
missing entry file
path traversal
large allocation
repeated exception
```

No crash may permanently prevent CrossInk core from booting.

---

# 31. Phase P3 — Native ZInk facade

Implement and test:

```text
ZInk.Display
ZInk.Input
ZInk.Storage
ZInk.UI
ZInk.Reader
ZInk.System
```

Network may be added later.

All APIs must map to existing CrossInk architecture rather than duplicate it.

---

# 32. Phase P4 — Network sandbox

Test:

```text
GET JSON
GET text
HTTPS
redirect
timeout
connection loss
large response
```

No browser engine.

No JavaScript runtime.

No unrestricted sockets exposed to the plugin.

---

# 33. Phase P5 — Z-Truyen native core

Build the smallest direct-mode prototype:

```text
source adapter
 ↓
search
 ↓
book
 ↓
chapter
```

Measure:

```text
heap
latency
flash size
SD writes
```

Do not build every source at once.

One source adapter is sufficient for the first proof.

---

# 34. Phase P6 — Z-Truyen document pipeline

Add:

```text
chapter fetch
 ↓
normalization
 ↓
lightweight EPUB build
 ↓
SD
 ↓
existing CrossInk reader
```

Test:

- Vietnamese Unicode;
- long chapter;
- 50 chapters;
- 200 chapters;
- large volume;
- cover;
- malformed HTML.

---

# 35. Phase P7 — Server fallback

Integrate the existing Z-Truyen server/OPDS ecosystem as an optional provider.

```text
ZTruyenProvider
 ├── DirectProvider
 └── ServerProvider
```

The plugin UI remains the same.

Only the provider changes.

---

# 36. Phase P8 — Consumer plugin installation

Test the full SD workflow:

```text
PC
 ↓
copy ZIP/folder
 ↓
SD
 ↓
X3 boot
 ↓
plugin discovered
 ↓
plugin enabled
 ↓
Z-Truyen launches
```

No firmware reflash.

---

# 37. Phase P9 — Physical X3 qualification

This is the most important project gate.

The AI agent MUST NOT jump here simply because the simulator passes.

The physical test sequence is:

```text
Known-good CrossInk
        ↓
Full flash backup
        ↓
SD backup
        ↓
Escape Hatch/recovery validated
        ↓
Z-CrossInk minimal Hello build
        ↓
boot test
        ↓
plugin safety test
        ↓
Z-Truyen test
```

---

# 38. Physical hardware acceptance matrix

## H001 — Boot

Expected:

- boot to Home;
- no boot loop;
- no excessive delay.

## H002 — Basic reading

- open known-good EPUB;
- page forward/back;
- sleep/wake;
- reopen.

## H003 — Plugin Manager

- open plugin list;
- launch Hello;
- exit;
- return to Home.

## H004 — Safe Mode

Install intentionally crashing plugin.

Expected:

```text
boot
↓
plugin crash
↓
reboot
↓
plugin disabled
↓
CrossInk still usable
```

## H005 — Z-Truyen

- Wi-Fi connect;
- search;
- book details;
- chapter;
- download;
- reader.

## H006 — Long-run

At least several hours of repeated:

```text
Home
→ plugin
→ search
→ book
→ reader
→ sleep
→ wake
```

Record heap and stability.

---

# 39. Firmware promotion policy

Three firmware classes:

### DEV

- simulator first;
- experimental;
- never consumer distributed.

### RC

- simulator PASS;
- physical X3 PASS;
- recovery tested;
- known issues documented.

### STABLE

- upstream sync recorded;
- physical regression PASS;
- recovery PASS;
- plugin regression PASS;
- no critical known issue.

---

# 40. No automatic physical flashing by AI

The AI agent may:

- build firmware;
- calculate checksum;
- create release artifacts;
- inspect flash logs;
- generate flashing instructions.

The AI agent MUST NOT:

- autonomously flash the user's physical X3;
- erase flash;
- repartition the device;
- change bootloader;
- modify efuses;
- change secure boot/flash encryption settings.

Physical flashing requires an explicit human approval gate.

---

# 41. Physical rollback plan

Maintain at minimum:

```text
recovery/
  escape-hatch.bin
  known-good-zcrossink.bin
  known-good-crossink.bin
  stock-or-golden-backup.bin
  SHA256SUMS.txt
  recovery.md
```

Before physical testing, verify the recovery media is readable and that the known-good firmware image passes the image validation tools used by the recovery workflow.

Escape Hatch supports flashing a selected `.bin` into the inactive OTA partition and switching the boot selector. citeturn423445search0

---

# 42. OTA strategy inside Z-CrossInk

Do not create a new OTA mechanism.

Use the existing ESP32 OTA mechanism and CrossInk/Escape Hatch recovery model.

Z-CrossInk plugin updates are **not firmware OTA**.

Plugin update:

```text
SD file replacement
```

Firmware update:

```text
separate trusted firmware process
```

This separation is mandatory.

---

# 43. Upstream update compatibility test

After every upstream CrossInk sync:

```text
1. Build stock upstream-equivalent CrossInk
2. Build Z-CrossInk
3. Compare modified-file set
4. Run unit tests
5. Build simulator
6. Run plugin tests
7. Run EPUB tests
8. Run network tests
9. Check firmware size
10. Generate sync report
```

If upstream modifies:

```text
src/main.cpp
ActivityManager
ReaderActivity
network
freeink-sdk
PowerManager
GfxRenderer
```

the agent must explicitly review Z-CrossInk integration points.

---

# 44. Compatibility contract with CrossInk

Z-CrossInk must preserve unless explicitly overridden:

- device detection;
- display initialization;
- power/sleep;
- SD mount;
- Wi-Fi;
- reader;
- EPUB cache;
- settings;
- localization;
- existing web server.

A Z-CrossInk feature regression in an unrelated upstream subsystem is a release blocker.

---

# 45. Test coverage requirement

Every plugin subsystem must have tests for:

```text
manifest parser
path validation
permission validation
plugin discovery
plugin enable/disable
plugin lifecycle
API bridge
crash guard
safe mode
reader integration
network integration
storage
```

Test fixtures:

```text
hello plugin
invalid manifest
missing entry
path traversal
bad API
crash plugin
large plugin
Z-Truyen minimal
```

---

# 46. Performance acceptance

At minimum measure:

```text
cold boot time
home screen memory
plugin load time
plugin unload time
Z-Truyen search time
chapter download time
EPUB build time
reader open time
```

No performance claim may be made without actual measurement.

---

# 47. Failure handling requirements

The firmware must gracefully handle:

```text
missing SD
corrupt manifest
missing Lua file
bad Lua
network unavailable
DNS failure
TLS failure
HTTP 404
HTTP 429
HTTP 500
source HTML changed
EPUB build failure
SD full
low battery
sleep during plugin
```

A plugin failure must not cause a firmware-wide endless reboot.

---

# 48. Z-Truyen-specific source strategy

The first release must not attempt to support every web novel site.

Start with one known stable source adapter and expand through isolated adapters.

Each adapter must have:

```text
search()
getBook()
getChapters()
getChapter()
getCover()
```

A source that requires JavaScript/browser automation MUST be marked unsupported in Direct Mode instead of attempting to run a browser inside the ESP32-C3 firmware.

---

# 49. EPUB strategy

Whenever possible, generated documents should be optimized for the CrossInk reader:

- avoid unnecessarily embedded fonts;
- minimize huge images;
- use clean XHTML;
- stable paragraph structure;
- stable identifiers;
- bounded document size;
- chapter-volume bundling.

CrossInk's existing EPUB engine explicitly uses SD-backed metadata, CSS and section caches because RAM is limited. citeturn343181search0

---

# 50. KOSync compatibility

Do not redesign KOSync as part of the initial plugin system.

The Z-Truyen plugin should generate deterministic document identity and stable content structure so the existing CrossInk/KOReader sync behavior has the best chance of remaining compatible.

Do not claim exact KOSync compatibility until a two-device E2E test passes.

Test matrix:

```text
Z-CrossInk X3 ↔ KOReader Android
Z-CrossInk X3 ↔ KOReader desktop
Z-CrossInk X3 ↔ another X3
```

---

# 51. Plugin API versioning

Plugin API must have its own version:

```text
ZPI 1.0
```

Manifest:

```json
{
  "apiVersion": 1
}
```

The firmware must reject unsupported API versions gracefully.

This is critical for upstream synchronization. A CrossInk firmware update must not silently execute an incompatible plugin.

---

# 52. Backward compatibility policy

Plugin package compatibility is independent of firmware version.

Example:

```text
Z-Truyen 1.2
  supports ZPI 1
  minZCrossInk 0.5
  maxTestedZCrossInk 0.8
```

The plugin manager must show:

```text
Compatible
Incompatible
Needs update
Disabled
Corrupt
```

rather than attempting to execute unsupported code.

---

# 53. Developer workflow

Developer should be able to:

```bash
git clone --recursive https://github.com/magicxlll/Z-CrossInk.git
cd Z-CrossInk
pio run
```

and then run the X3 simulator.

Developer test flow:

```text
modify plugin
 ↓
run plugin unit tests
 ↓
build simulator
 ↓
launch X3 simulator
 ↓
load plugin from test SD
 ↓
exercise plugin
 ↓
collect logs
```

No physical X3 is required for routine development.

---

# 54. Consumer workflow

The final consumer goal is:

```text
copy plugin to SD
↓
X3 boot
↓
plugin appears
↓
launch
```

For Z-Truyen specifically:

```text
Z-Truyen
 ↓
Search
 ↓
Select story
 ↓
Select volume/chapter
 ↓
Download
 ↓
Open with native reader
```

Optional later integrations:

```text
Android Z-Truyen companion
Mac mini
Cloud
```

These are optional providers, not mandatory dependencies for the plugin platform.

---

# 55. “One firmware, many plugins” target

The product must be able to support at least:

```text
Z-Truyen
Dictionary
Clock
Weather
Notes
Simple games
Reader utilities
```

without changing firmware for each plugin.

This is the main reason the plugin layer exists.

---

# 56. Anti-goal: plugin sprawl

The plugin framework must not expose every internal CrossInk feature.

Every new API requires:

```text
use case
security review
memory cost
API ownership
upstream conflict analysis
```

A smaller stable ABI is preferable to a large unstable one.

---

# 57. Governance of upstream changes

When upstream adds a feature already covered by Z-CrossInk:

1. prefer upstream implementation;
2. delete the local duplicate when safe;
3. keep the Z-CrossInk layer thin;
4. document compatibility change.

If upstream changes an internal API:

```text
update adapter
not every plugin
```

This is why the `ZInk` facade must remain stable.

---

# 58. Definition of Done — Plugin platform

Plugin platform is considered implemented only when all are PASS:

```text
[ ] plugin discovery
[ ] manifest validation
[ ] plugin activity
[ ] display API
[ ] input API
[ ] storage sandbox
[ ] permission enforcement
[ ] runtime memory budget
[ ] crash guard
[ ] safe mode
[ ] reader handoff
[ ] plugin update
[ ] simulator regression
[ ] physical X3 regression
```

---

# 59. Definition of Done — Z-Truyen plugin

```text
[ ] direct search
[ ] story details
[ ] chapter list
[ ] chapter download
[ ] EPUB generation
[ ] cover
[ ] SD storage
[ ] native CrossInk reader
[ ] offline reading
[ ] one stable source adapter
[ ] memory stress
[ ] failure handling
[ ] optional server provider
[ ] KOSync qualification
```

---

# 60. Definition of Done — upstream compatibility

```text
[ ] upstream remote configured
[ ] upstream SHA recorded
[ ] sync procedure documented
[ ] diff report generated
[ ] simulator passes
[ ] plugin passes
[ ] reader passes
[ ] network passes
[ ] no bootloader changes
[ ] no partition changes
[ ] physical X3 smoke test passes
```

---

# 61. Mandatory AI agent reporting format

After every task, report:

```text
TASK

Changed files:

Upstream files modified:

New files:

Why:

Tests:

Simulator result:

Physical device result:

Firmware size impact:

Heap impact:

Recovery impact:

Known issues:

Upstream compatibility impact:

Next gate:
```

The agent must distinguish:

```text
IMPLEMENTED
TESTED
SIMULATOR VERIFIED
PHYSICAL VERIFIED
ASSUMED
```

Never convert an assumption into a fact.

---

# 62. Mandatory stop conditions

The AI agent MUST stop and ask for human review when:

- partition table modification appears necessary;
- bootloader modification appears necessary;
- `freeink-sdk` hardware code must be changed;
- E-Ink driver must be changed;
- firmware size approaches/exceeds the app partition;
- a plugin can access unrestricted native pointers;
- plugin crashes happen before safe-mode state is recorded;
- physical X3 behavior differs from simulator in a potentially dangerous way;
- upstream changes make the plugin ABI unsafe;
- recovery has not been validated.

---

# 63. Recommended physical test ladder for the user's X3

The project owner's current X3 is the primary hardware qualification device.

Recommended sequence:

```text
Known-good current CrossPoint/CrossInk
        ↓
full flash backup
        ↓
SD backup
        ↓
recovery media verified
        ↓
Z-CrossInk hello plugin firmware
        ↓
physical boot
        ↓
plugin enable/disable
        ↓
safe-mode crash test
        ↓
Z-Truyen minimal
        ↓
Z-Truyen direct mode
        ↓
large EPUB
        ↓
network reconnect
        ↓
sleep/wake
        ↓
long soak test
```

Do not begin with a large Z-Truyen feature bundle.

---

# 64. Why this architecture is the right risk trade-off

A monolithic fork would look like:

```text
CrossInk
  ↓
modify everything
  ↓
Z-Truyen built into firmware
```

That creates a large perpetual merge burden.

The proposed architecture is:

```text
CrossInk upstream
       │
       └── thin Z-CrossInk seams
                  │
                  └── stable Plugin ABI
                         │
                         └── Z-Truyen on SD
```

Benefits:

- upstream sync remains realistic;
- users install/update plugins without firmware reflashing;
- Z-Truyen source adapters can evolve independently;
- firmware hardware stack remains stable;
- recovery model remains compatible with existing OTA/SD tooling;
- a plugin bug can be disabled without replacing the firmware.

---

# 65. Final architecture target

```text
                         Z-CROSSINK
                              │
          ┌───────────────────┴──────────────────┐
          │                                      │
      CrossInk Core                         Plugin Runtime
          │                                      │
  ┌───────┼─────────┐                    ┌──────┴───────┐
  │       │         │                    │              │
 HAL    Reader    Network              Lua UI      Native APIs
  │       │         │                    │              │
  │       │         │                    └──────┬───────┘
  │       │         │                           │
  └───────┴─────────┴───────────────────────────┘
                              │
                    Plugin ecosystem
                              │
                     ┌────────┴────────┐
                     │                 │
                  Z-Truyen        Other plugins
                     │
          ┌──────────┴──────────┐
          │                     │
      Direct Web             Optional server
          │                     │
          └──────────┬──────────┘
                     │
                    X3
```

---

# 66. First AI-agent command

The agent must begin with **Phase P0 only**.

Use this exact task:

```text
Read Z-CrossInk Master Engineering Specification completely.

Do NOT flash any physical X3.
Do NOT repartition flash.
Do NOT modify bootloader.
Do NOT modify efuses/security settings.
Do NOT change the freeink-sdk hardware layer.
Do NOT add new Z-Truyen functionality yet.

Task: perform PHASE P0 — REPOSITORY REALITY AUDIT.

1. Inspect the complete current Z-CrossInk repository.
2. Identify every file modified relative to upstream CrossInk.
3. Identify the current plugin runtime implementation.
4. Identify the current plugin UI/activity integration.
5. Identify actual manifest parsing.
6. Identify whether Lua is embedded and which exact version/build configuration is used.
7. Identify all existing ZInk APIs.
8. Identify actual safe-mode/crash-guard code.
9. Identify actual SD plugin directory behavior.
10. Identify exact CrossInk ActivityManager integration points.
11. Identify all changes that touch boot, partitioning, OTA, display, GPIO, power, or freeink-sdk.
12. Build the current simulator without changing production code.
13. Run the existing plugin smoke tests.
14. Produce:
    docs/PHASE_P0_REALITY_AUDIT.md
    docs/PHASE_P0_UPSTREAM_DIFF.md
    docs/PHASE_P0_SAFETY_REVIEW.md

For every feature, classify it as:
EXISTING / PARTIAL / PROPOSED / MISSING / UNSAFE.

Do not implement the next phase until P0 is complete and the report is reviewable.
```

---

# 67. Final engineering rule

The project succeeds only if all three goals are true at the same time:

```text
1. Z-CrossInk behaves like CrossInk to the user
   except for deliberate plugin extensions.

2. Z-Truyen can be installed/updated independently as a plugin.

3. A bad plugin does not require a firmware reflash and does not
   compromise the boot/recovery path.
```

The highest priority is **not feature count**.

The highest priority is:

> **Keep the hardware core stable, keep the upstream diff small, and make the plugin layer disposable/recoverable.**

CrossInk's current architecture and CrossPoint's recovery tooling make this a credible engineering direction, but they do not make the result automatically safe. Every safety claim must be proven with simulator and real-X3 evidence. citeturn343181search0turn423445search0

---

## Sources / references

- CrossInk upstream architecture: https://github.com/uxjulia/CrossInk/blob/main/docs/contributing/architecture.md
- CrossInk repository: https://github.com/uxjulia/CrossInk
- CrossPoint recovery Escape Hatch: https://github.com/crosspoint-reader/escape-hatch
- CrossPoint tools/debug: https://github.com/crosspoint-reader/crosspoint-tools
- Supplied Z-Plugin specification: `Z_PLUGIN_SPEC.md`
- Supplied Z-Plugin developer guide: `Z_PLUGIN_DEVELOPER_GUIDE.md`

**Important:** The two supplied Z-Plugin documents are treated as product/design requirements where explicitly marked above, not as proof that the corresponding APIs already exist in upstream CrossInk.
