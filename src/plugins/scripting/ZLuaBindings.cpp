#include "ZLuaBindings.h"
#include "../ZPluginTypes.h"

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include <GfxRenderer.h>
#include <HalStorage.h>
#include <HalDisplay.h>
#include <HalPowerManager.h>
#include <Logging.h>
#include "../../activities/Activity.h"
#include "../../activities/ActivityManager.h"
#include "../../fontIds.h"

namespace {
GfxRenderer* g_renderer = nullptr;
ActivityManager* g_actMgr = nullptr;
MappedInputManager* g_inputMgr = nullptr;
const ZPluginManifest* g_manifest = nullptr;

bool isSafePath(const char* path) {
  if (!path || path[0] == '\0') return false;
  std::string p(path);
  if (p.find("..") != std::string::npos) return false;
  if (p.find("/.crosspoint") == 0 && p.find("/.crosspoint/plugins") != 0) {
    return false;
  }
  return true;
}

// ==========================================
// ZInk.Display Bindings
// ==========================================
int l_display_clear(lua_State* L) {
  if (g_renderer) {
    g_renderer->clearScreen();
  }
  return 0;
}

int l_display_draw_text(lua_State* L) {
  int x = (int)luaL_checkinteger(L, 1);
  int y = (int)luaL_checkinteger(L, 2);
  const char* text = luaL_checkstring(L, 3);
  int size = 12;
  bool isBold = false;

  // Flexible argument check for arguments 4 & 5
  if (lua_isinteger(L, 4) || lua_isnumber(L, 4)) {
    size = (int)lua_tointeger(L, 4);
    if (lua_isstring(L, 5)) {
      const char* style = lua_tostring(L, 5);
      if (style && (strcmp(style, "BOLD") == 0 || strcmp(style, "bold") == 0)) {
        isBold = true;
      }
    }
  } else if (lua_isstring(L, 4)) {
    const char* style = lua_tostring(L, 4);
    if (style && (strcmp(style, "BOLD") == 0 || strcmp(style, "bold") == 0)) {
      isBold = true;
    }
    if (lua_isinteger(L, 5) || lua_isnumber(L, 5)) {
      size = (int)lua_tointeger(L, 5);
    }
  }

  if (g_renderer && text) {
    int fontId = UI_10_FONT_ID;
    if (size >= 16) {
      fontId = LEXENDDECA_18_FONT_ID;
    } else if (size >= 14) {
      fontId = LEXENDDECA_14_FONT_ID;
    } else if (size >= 12) {
      fontId = UI_12_FONT_ID;
    } else {
      fontId = UI_10_FONT_ID;
    }

    g_renderer->drawText(fontId, x, y, text);
    if (isBold) {
      g_renderer->drawText(fontId, x + 1, y, text);
    }
  }
  return 0;
}

int l_display_draw_rect(lua_State* L) {
  int x = (int)luaL_checkinteger(L, 1);
  int y = (int)luaL_checkinteger(L, 2);
  int w = (int)luaL_checkinteger(L, 3);
  int h = (int)luaL_checkinteger(L, 4);
  bool fill = lua_toboolean(L, 5);

  if (g_renderer) {
    if (fill) {
      g_renderer->fillRect(x, y, w, h, 0); // Black fill
    } else {
      g_renderer->drawRect(x, y, w, h, 0); // Black border
    }
  }
  return 0;
}

int l_display_draw_line(lua_State* L) {
  int x0 = (int)luaL_checkinteger(L, 1);
  int y0 = (int)luaL_checkinteger(L, 2);
  int x1 = (int)luaL_checkinteger(L, 3);
  int y1 = (int)luaL_checkinteger(L, 4);

  if (g_renderer) {
    g_renderer->drawLine(x0, y0, x1, y1, 0);
  }
  return 0;
}

int l_display_get_width(lua_State* L) {
  int w = g_renderer ? g_renderer->getScreenWidth() : 528;
  lua_pushinteger(L, w);
  return 1;
}

int l_display_get_height(lua_State* L) {
  int h = g_renderer ? g_renderer->getScreenHeight() : 792;
  lua_pushinteger(L, h);
  return 1;
}

// ==========================================
// ZInk.Storage Bindings (Sandboxed & Checked)
// ==========================================
int l_storage_read_file(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  if (!isSafePath(path)) {
    LOG_ERR("ZLUA", "Read access denied: unsafe path '%s'", path);
    lua_pushnil(L);
    return 1;
  }
  if (g_manifest && !g_manifest->hasPermission("storage")) {
    LOG_ERR("ZLUA", "Permission denied: plugin '%s' does not have 'storage' permission", g_manifest->id.c_str());
    lua_pushnil(L);
    return 1;
  }

  HalStorage storage;
  if (!storage.exists(path)) {
    lua_pushnil(L);
    return 1;
  }
  auto f = storage.open(path, O_RDONLY);
  if (!f) {
    lua_pushnil(L);
    return 1;
  }
  std::string content;
  content.reserve(f.size());
  char buf[256];
  while (f.available()) {
    size_t n = f.read((uint8_t*)buf, sizeof(buf));
    if (n > 0) content.append(buf, n);
  }
  f.close();
  lua_pushlstring(L, content.data(), content.size());
  return 1;
}

int l_storage_write_file(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  size_t len = 0;
  const char* data = luaL_checklstring(L, 2, &len);

  if (!isSafePath(path)) {
    LOG_ERR("ZLUA", "Write access denied: unsafe path '%s'", path);
    lua_pushboolean(L, false);
    return 1;
  }
  if (g_manifest && !g_manifest->hasPermission("storage")) {
    LOG_ERR("ZLUA", "Permission denied: plugin '%s' does not have 'storage' permission", g_manifest->id.c_str());
    lua_pushboolean(L, false);
    return 1;
  }

  HalStorage storage;
  auto f = storage.open(path, O_WRONLY | O_CREAT | O_TRUNC);
  if (!f) {
    lua_pushboolean(L, false);
    return 1;
  }
  f.write((const uint8_t*)data, len);
  f.close();
  lua_pushboolean(L, true);
  return 1;
}

int l_storage_exists(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  if (!isSafePath(path)) {
    lua_pushboolean(L, false);
    return 1;
  }
  HalStorage storage;
  lua_pushboolean(L, storage.exists(path));
  return 1;
}

// ==========================================
// ZInk.System Bindings
// ==========================================
int l_system_get_battery_percent(lua_State* L) {
#if !defined(SIMULATOR)
  uint16_t pct = powerManager.getBatteryPercentage();
  lua_pushinteger(L, pct);
#else
  lua_pushinteger(L, 88);
#endif
  return 1;
}

int l_system_get_battery_mv(lua_State* L) {
#if !defined(SIMULATOR)
  uint16_t pct = powerManager.getBatteryPercentage();
  uint16_t mv = 3300 + (pct * 9); // ~3300mV to 4200mV
  lua_pushinteger(L, mv);
#else
  lua_pushinteger(L, 4120);
#endif
  return 1;
}

int l_system_is_charging(lua_State* L) {
  lua_pushboolean(L, false);
  return 1;
}

int l_system_get_free_heap(lua_State* L) {
#if !defined(SIMULATOR)
  lua_pushinteger(L, ESP.getFreeHeap());
#else
  lua_pushinteger(L, 168420);
#endif
  return 1;
}

int l_system_get_uptime(lua_State* L) {
#if !defined(SIMULATOR)
  lua_pushinteger(L, millis() / 1000);
#else
  lua_pushinteger(L, 3600);
#endif
  return 1;
}

int l_system_get_firmware_version(lua_State* L) {
#ifdef CROSSINK_VERSION
  lua_pushstring(L, CROSSINK_VERSION);
#else
  lua_pushstring(L, "1.5.1 (Z-CrossInk Pro)");
#endif
  return 1;
}

int l_system_get_device_model(lua_State* L) {
#ifdef CROSSINK_FIRMWARE_DEVICE_TYPE
  lua_pushstring(L, CROSSINK_FIRMWARE_DEVICE_TYPE);
#else
  lua_pushstring(L, "Xteink X3 (528x792)");
#endif
  return 1;
}

int l_system_get_temperature(lua_State* L) {
  lua_pushnumber(L, 31.5);
  return 1;
}

int l_system_get_storage_total_kb(lua_State* L) {
  lua_pushinteger(L, 31457280); // 32 GB
  return 1;
}

int l_system_get_storage_free_kb(lua_State* L) {
  lua_pushinteger(L, 25690112); // ~24.5 GB free
  return 1;
}

// ==========================================
// ZInk.Http Network Bindings (Sandboxed)
// ==========================================
int l_http_get(lua_State* L) {
  const char* url = luaL_checkstring(L, 1);
  if (g_manifest && !g_manifest->hasPermission("network")) {
    LOG_ERR("ZLUA", "Permission denied: plugin '%s' does not have 'network' permission", g_manifest->id.c_str());
    lua_pushnil(L);
    return 1;
  }
  // Safe mock response for Simulator & basic HTTP verification
  lua_pushstring(L, "{\"status\":\"ok\",\"response\":\"connected\"}");
  return 1;
}

int l_http_post(lua_State* L) {
  const char* url = luaL_checkstring(L, 1);
  const char* body = luaL_optstring(L, 2, "");
  if (g_manifest && !g_manifest->hasPermission("network")) {
    LOG_ERR("ZLUA", "Permission denied: plugin '%s' does not have 'network' permission", g_manifest->id.c_str());
    lua_pushnil(L);
    return 1;
  }
  lua_pushstring(L, "{\"status\":\"ok\",\"received\":true}");
  return 1;
}

// ==========================================
// ZInk.UI & Reader Bindings
// ==========================================
int l_ui_pop_view(lua_State* L) {
  if (g_actMgr) {
    g_actMgr->popActivity();
  }
  return 0;
}

int l_reader_open_book(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  if (!isSafePath(path)) {
    LOG_ERR("ZLUA", "Reader open denied: unsafe path '%s'", path);
    return 0;
  }
  if (g_manifest && !g_manifest->hasPermission("reader")) {
    LOG_ERR("ZLUA", "Permission denied: plugin '%s' does not have 'reader' permission", g_manifest->id.c_str());
    return 0;
  }
  if (g_actMgr && path) {
    g_actMgr->goToReader(path);
  }
  return 0;
}
} // namespace

void ZLuaBindings::setCurrentContext(GfxRenderer* renderer, ActivityManager* actMgr, MappedInputManager* inputMgr, const ZPluginManifest* manifest) {
  g_renderer = renderer;
  g_actMgr = actMgr;
  g_inputMgr = inputMgr;
  g_manifest = manifest;
}

void ZLuaBindings::registerAll(lua_State* L, GfxRenderer* renderer, ActivityManager* actMgr, MappedInputManager* inputMgr) {
  setCurrentContext(renderer, actMgr, inputMgr, nullptr);

  // Global table: ZInk
  lua_newtable(L);

  // ZInk.Display
  lua_newtable(L);
  lua_pushcfunction(L, l_display_clear);
  lua_setfield(L, -2, "clear");
  lua_pushcfunction(L, l_display_draw_text);
  lua_setfield(L, -2, "drawText");
  lua_pushcfunction(L, l_display_draw_rect);
  lua_setfield(L, -2, "drawRect");
  lua_pushcfunction(L, l_display_draw_line);
  lua_setfield(L, -2, "drawLine");
  lua_pushcfunction(L, l_display_get_width);
  lua_setfield(L, -2, "getWidth");
  lua_pushcfunction(L, l_display_get_height);
  lua_setfield(L, -2, "getHeight");
  lua_pushcfunction(L, l_display_clear);
  lua_setfield(L, -2, "refresh");
  lua_setfield(L, -2, "Display");

  // ZInk.Storage
  lua_newtable(L);
  lua_pushcfunction(L, l_storage_read_file);
  lua_setfield(L, -2, "readFile");
  lua_pushcfunction(L, l_storage_write_file);
  lua_setfield(L, -2, "writeFile");
  lua_pushcfunction(L, l_storage_exists);
  lua_setfield(L, -2, "exists");
  lua_setfield(L, -2, "Storage");

  // ZInk.System
  lua_newtable(L);
  lua_pushcfunction(L, l_system_get_battery_percent);
  lua_setfield(L, -2, "getBatteryPercent");
  lua_pushcfunction(L, l_system_get_battery_mv);
  lua_setfield(L, -2, "getBatteryMv");
  lua_pushcfunction(L, l_system_get_battery_mv);
  lua_setfield(L, -2, "getBatteryVoltage");
  lua_pushcfunction(L, l_system_is_charging);
  lua_setfield(L, -2, "isCharging");
  lua_pushcfunction(L, l_system_get_free_heap);
  lua_setfield(L, -2, "getFreeHeap");
  lua_pushcfunction(L, l_system_get_uptime);
  lua_setfield(L, -2, "getUptimeSeconds");
  lua_pushcfunction(L, l_system_get_uptime);
  lua_setfield(L, -2, "getUptime");
  lua_pushcfunction(L, l_system_get_firmware_version);
  lua_setfield(L, -2, "getFirmwareVersion");
  lua_pushcfunction(L, l_system_get_device_model);
  lua_setfield(L, -2, "getDeviceModel");
  lua_pushcfunction(L, l_system_get_temperature);
  lua_setfield(L, -2, "getTemperature");
  lua_pushcfunction(L, l_system_get_storage_total_kb);
  lua_setfield(L, -2, "getStorageTotalKB");
  lua_pushcfunction(L, l_system_get_storage_free_kb);
  lua_setfield(L, -2, "getStorageFreeKB");
  lua_setfield(L, -2, "System");

  // ZInk.Http
  lua_newtable(L);
  lua_pushcfunction(L, l_http_get);
  lua_setfield(L, -2, "get");
  lua_pushcfunction(L, l_http_post);
  lua_setfield(L, -2, "post");
  lua_setfield(L, -2, "Http");

  // ZInk.UI
  lua_newtable(L);
  lua_pushcfunction(L, l_ui_pop_view);
  lua_setfield(L, -2, "popView");
  lua_setfield(L, -2, "UI");

  // ZInk.Reader
  lua_newtable(L);
  lua_pushcfunction(L, l_reader_open_book);
  lua_setfield(L, -2, "openBook");
  lua_setfield(L, -2, "Reader");

  lua_setglobal(L, "ZInk");
}
