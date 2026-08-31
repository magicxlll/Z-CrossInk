# Z-CrossInk Dynamic Plugin Specification (Z-Plugin Spec v1.0)

> **Standard for Extensible Community Plugins on E-ink Readers (CrossInk / Xteink X3 & X4)**

---

## 1. Overview & Architecture Philosophy

Z-CrossInk introduces an extensible, dynamic runtime plugin architecture inspired by KOReader. It allows developers and community creators to develop, install, and run plugins directly from the SD card **without compiling or reflashing the firmware**.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Z-PLUGIN ARCHITECTURE (SD CARD)                      │
│                                                                         │
│  SD Card Directory: /.crosspoint/plugins/  or  /plugins/                │
│                                                                         │
│  /plugins/                                                              │
│  ├── ztruyen/                ──> [Flagship Z-Truyen E-ink Portal]       │
│  │   ├── manifest.json                                                  │
│  │   ├── main.lua                                                       │
│  │   └── icon.bmp                                                       │
│  ├── dictionary_viet/        ──> [Offline Vietnamese-English Dict]      │
│  │   ├── manifest.json                                                  │
│  │   └── dict.lua                                                       │
│  └── custom_clock/           ──> [Custom Sleep Screen / Widget]         │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                      Z-Plugin Engine Host                         │  │
│  │  • Manifest Parser (ArduinoJson 7.4.2)                            │  │
│  │  • Featherweight Lua 5.4 Mini Sandbox (32KB Heap Capped)          │  │
│  │  • E-ink Display & Input C++ Bindings                             │  │
│  │  • Zero-Brick Hardware Safe Boot Guard Interceptor                │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Directory & File Structure

Every plugin is stored in its own dedicated directory on the SD card:

```text
/plugins/<plugin_id>/
  ├── manifest.json       (Required: Plugin metadata, category, permissions)
  ├── main.lua            (Required: Plugin logic entrypoint script)
  ├── icon.bmp            (Optional: 32x32 or 48x48 1-bit monochrome icon)
  ├── config.json         (Optional: User-customizable settings)
  └── assets/             (Optional: Static images, dictionaries, fonts)
```

---

## 3. Plugin Manifest Specification (`manifest.json`)

The `manifest.json` file defines the plugin identity and capabilities:

```json
{
  "id": "ztruyen",
  "name": "Z-Truyen E-ink Portal",
  "version": "1.0.0",
  "author": "Z-Truyen Community",
  "description": "Kho truyen truc tuyen va dong bo 2 chieu KOSync cho CrossInk",
  "category": "HOME_APP",
  "entry": "main.lua",
  "icon": "book_open",
  "enabled": true,
  "priority": 10,
  "minFirmwareVersion": "1.5.1",
  "permissions": [
    "display",
    "input",
    "network",
    "storage",
    "reader"
  ],
  "settings": {
    "serverUrl": "http://192.168.1.11:8080",
    "autoSyncOnOpen": true
  }
}
```

### Manifest Fields Description

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `id` | `string` | **Yes** | Unique alphanumeric ID (e.g. `ztruyen`, `quick_dict`). |
| `name` | `string` | **Yes** | Human-readable title displayed on screen. |
| `version` | `string` | **Yes** | Semantic version string (e.g. `1.0.0`). |
| `author` | `string` | No | Author or organization name. |
| `category` | `string` | **Yes** | Category type: `HOME_APP`, `READER_TOOL`, `NETWORK_SYNC`, `SYSTEM_TOOL`. |
| `entry` | `string` | **Yes** | Script entry file (default: `main.lua`). |
| `icon` | `string` | No | Icon identifier from built-in vector icons or path to `.bmp`. |
| `enabled` | `boolean`| No | Default active state (default: `true`). |
| `priority` | `number` | No | Sorting order (lower number = higher priority). |
| `permissions`| `array`  | No | Requested system access scopes. |

---

## 4. Plugin Categories & Lifecycle

### A. Plugin Categories

1. **`HOME_APP`**: Appears on the main Home Carousel alongside standard functions (File Browser, Recents, Settings). When chosen, launches the plugin's full-screen UI.
2. **`READER_TOOL`**: Injected into the in-book Reader menu when reading an EPUB. Ideal for dictionaries, text-to-speech, translation, and chapter bookmarks.
3. **`NETWORK_SYNC`**: Background wireless tasks executed when Wi-Fi is connected (such as automatic KOSync progress sync, OPDS catalog updates).
4. **`SYSTEM_TOOL`**: Utility tools for maintenance, storage diagnosis, or battery statistics.

### B. Standard Plugin Lifecycle Events (Lua)

In `main.lua`, a plugin can define standard lifecycle callbacks:

```lua
-- Called when plugin is first discovered and loaded
function onInit()
    print("Plugin initialized")
end

-- Called when user opens the plugin from Home menu
function onEnter()
    ZInk.Display.clear()
    ZInk.Display.drawText(20, 40, "Z-Truyen Portal", "BOLD", 16)
    ZInk.Display.refresh(false) -- Fast E-ink refresh
end

-- Called on physical button press
-- key: "BACK", "CONFIRM", "LEFT", "RIGHT", "POWER", "VOL_UP", "VOL_DOWN"
-- eventType: "PRESS", "RELEASE", "HOLD"
function onInput(key, eventType)
    if key == "BACK" and eventType == "RELEASE" then
        ZInk.UI.popView() -- Return to previous screen
        return true
    end
    return false
end

-- Called when leaving the screen
function onExit()
end
```

---

## 5. Z-Ink Lua 5.4 Sandbox API Reference

The embedded sandbox exposes safe, memory-controlled C++ functions under the global `ZInk` namespace:

### 1. `ZInk.Display` (E-ink Graphics & Typography)
- `ZInk.Display.clear(color)`: Clears screen buffer (0 = White, 1 = Black).
- `ZInk.Display.drawText(x, y, text, style, size)`: Draws text at coordinates.
  - `style`: `"REGULAR"`, `"BOLD"`, `"ITALIC"`.
  - `size`: `10`, `12`, `14`, `16`, `20`, `24`.
- `ZInk.Display.drawRect(x, y, w, h, filled)`: Draws outline or filled rectangle.
- `ZInk.Display.drawLine(x1, y1, x2, y2)`: Draws line.
- `ZInk.Display.drawBitmap(x, y, bmpPath)`: Draws monochrome 1-bit BMP image.
- `ZInk.Display.refresh(fullRefresh)`: Triggers E-ink screen update.
  - `fullRefresh = false`: Fast grayscale update (~200ms).
  - `fullRefresh = true`: Full clear & refresh to eliminate ghosting (~800ms).
- `ZInk.Display.getWidth()`: Returns screen width (e.g. `528` for X3).
- `ZInk.Display.getHeight()`: Returns screen height (e.g. `792` for X3).

### 2. `ZInk.Input` (Physical Buttons & Gestures)
- `ZInk.Input.isPressed(keyName)`: Checks if a button is currently pressed.

### 3. `ZInk.Http` (Wireless Network Client)
- `ZInk.Http.get(url, timeoutMs)`: Performs HTTP GET, returns `{ status = 200, body = "..." }`.
- `ZInk.Http.post(url, body, contentType, timeoutMs)`: Performs HTTP POST.
- `ZInk.Http.download(url, destPath)`: Downloads file directly to SD card, returns `true`/`false`.

### 4. `ZInk.Storage` (SD Card Filesystem)
- `ZInk.Storage.readFile(path)`: Reads text file content.
- `ZInk.Storage.writeFile(path, content)`: Writes text file content.
- `ZInk.Storage.exists(path)`: Checks if file or directory exists.
- `ZInk.Storage.listDir(path)`: Returns array of `{ name = "...", isDir = true/false, size = 1234 }`.
- `ZInk.Storage.remove(path)`: Deletes file.
- `ZInk.Storage.mkdir(path)`: Creates directory.

### 5. `ZInk.Reader` (E-Reader Integration)
- `ZInk.Reader.openBook(epubPath)`: Directly launches CrossInk native reader for the EPUB.
- `ZInk.Reader.getCurrentBookPath()`: Returns path of current/last opened book.
- `ZInk.Reader.syncProgress(serverUrl, user, pass)`: Triggers KOReader 2-way sync.

### 6. `ZInk.UI` (Dialogs & Navigation)
- `ZInk.UI.showToast(message, durationMs)`: Shows bottom floating toast notice.
- `ZInk.UI.showDialog(title, message, buttons)`: Displays modal alert.
- `ZInk.UI.popView()`: Closes current plugin screen and returns to previous activity.

---

## 6. Zero-Brick Hardware Safety Rules for Plugins

1. **Strict Heap Limit**: Lua engine memory allocator is hard-capped at **32KB RAM**. Exceeding allocations safely aborts the script rather than crashing FreeRTOS.
2. **Watchdog Timeout**: Any event handler blocking for longer than **2.0 seconds** is automatically interrupted.
3. **Safe Mode Recovery**: If a plugin causes repeated crashes, holding the `Back` button on boot or triggering 3 consecutive resets disables all external plugins and boots pure CrossInk core safely.
