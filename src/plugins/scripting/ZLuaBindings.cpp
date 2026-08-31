#include "ZLuaBindings.h"

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include <GfxRenderer.h>
#include <HalStorage.h>
#include <HalDisplay.h>
#include <Logging.h>
#include "../../activities/ActivityManager.h"
#include "../../fontIds.h"

namespace {
GfxRenderer* g_renderer = nullptr;
ActivityManager* g_actMgr = nullptr;
MappedInputManager* g_inputMgr = nullptr;

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
  int size = (int)luaL_optinteger(L, 5, 12);

  if (g_renderer && text) {
    // Default to medium font size
    g_renderer->drawText(UIFontId::Default, x, y, text);
  }
  return 0;
}

int l_display_draw_rect(lua_State* L) {
  int x = (int)luaL_checkinteger(L, 1);
  int y = (int)luaL_checkinteger(L, 2);
  int w = (int)luaL_checkinteger(L, 3);
  int h = (int)luaL_checkinteger(L, 4);
  bool filled = lua_toboolean(L, 5);

  if (g_renderer) {
    if (filled) {
      g_renderer->fillRect(x, y, w, h, 0); // Black
    } else {
      g_renderer->drawRect(x, y, w, h, 0);
    }
  }
  return 0;
}

int l_display_draw_line(lua_State* L) {
  int x1 = (int)luaL_checkinteger(L, 1);
  int y1 = (int)luaL_checkinteger(L, 2);
  int x2 = (int)luaL_checkinteger(L, 3);
  int y2 = (int)luaL_checkinteger(L, 4);

  if (g_renderer) {
    g_renderer->drawLine(x1, y1, x2, y2, 0);
  }
  return 0;
}

int l_display_get_width(lua_State* L) {
  int w = g_renderer ? g_renderer->getDisplayWidth() : 528;
  lua_pushinteger(L, w);
  return 1;
}

int l_display_get_height(lua_State* L) {
  int h = g_renderer ? g_renderer->getDisplayHeight() : 792;
  lua_pushinteger(L, h);
  return 1;
}

// ==========================================
// ZInk.Storage Bindings
// ==========================================
int l_storage_read_file(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  if (!storage.exists(path)) {
    lua_pushnil(L);
    return 1;
  }
  auto f = storage.open(path, "r");
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

  auto f = storage.open(path, "w");
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
  lua_pushboolean(L, storage.exists(path));
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
  if (g_actMgr && path) {
    g_actMgr->goToReader(path);
  }
  return 0;
}
} // namespace

void ZLuaBindings::setCurrentContext(GfxRenderer* renderer, ActivityManager* actMgr, MappedInputManager* inputMgr) {
  g_renderer = renderer;
  g_actMgr = actMgr;
  g_inputMgr = inputMgr;
}

void ZLuaBindings::registerAll(lua_State* L, GfxRenderer* renderer, ActivityManager* actMgr, MappedInputManager* inputMgr) {
  setCurrentContext(renderer, actMgr, inputMgr);

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
