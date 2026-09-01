#include "ZLuaEngine.h"
#include "ZLuaBindings.h"
#include <HalStorage.h>
#include <Logging.h>
#include <cstdlib>
#include <vector>

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

void* ZLuaEngine::customAlloc(void* ud, void* ptr, size_t osize, size_t nsize) {
  size_t* totalAllocated = (size_t*)ud;
  if (nsize == 0) {
    if (ptr) {
      if (*totalAllocated >= osize) {
        *totalAllocated -= osize;
      } else {
        *totalAllocated = 0;
      }
      free(ptr);
    }
    return nullptr;
  }

  // Safety check: Capped heap limit (32KB for ESP32-C3)
  if (*totalAllocated + nsize - osize > ZConfig::MAX_PLUGIN_HEAP_BYTES) {
    LOG_ERR("ZLUA", "Lua memory limit exceeded (%u bytes)! Refusing allocation of %u bytes",
            (unsigned)*totalAllocated, (unsigned)nsize);
    return nullptr;
  }

  void* nptr = realloc(ptr, nsize);
  if (nptr) {
    *totalAllocated += nsize - osize;
  }
  return nptr;
}

ZLuaEngine::ZLuaEngine() {}

ZLuaEngine::~ZLuaEngine() {
  shutdown();
}

bool ZLuaEngine::init() {
  if (isInitialized) return true;

  memoryAllocated = 0;
  L = lua_newstate(customAlloc, &memoryAllocated);
  if (!L) {
    LOG_ERR("ZLUA", "Failed to create Lua state sandbox!");
    return false;
  }

  // Open safe subset of standard libraries
  luaL_requiref(L, "_G", luaopen_base, 1);
  lua_pop(L, 1);
  luaL_requiref(L, LUA_TABLIBNAME, luaopen_table, 1);
  lua_pop(L, 1);
  luaL_requiref(L, LUA_STRLIBNAME, luaopen_string, 1);
  lua_pop(L, 1);
  luaL_requiref(L, LUA_MATHLIBNAME, luaopen_math, 1);
  lua_pop(L, 1);
  luaL_requiref(L, LUA_UTF8LIBNAME, luaopen_utf8, 1);
  lua_pop(L, 1);

  // Register ZInk bindings
  ZLuaBindings::registerAll(L, nullptr, nullptr, nullptr);

  isInitialized = true;
  LOG_INF("ZLUA", "Lua sandbox initialized successfully. Memory used: %u bytes", (unsigned)memoryAllocated);
  return true;
}

void ZLuaEngine::shutdown() {
  if (L) {
    lua_close(L);
    L = nullptr;
  }
  isInitialized = false;
  memoryAllocated = 0;
}

bool ZLuaEngine::runString(const std::string& script) {
  if (!isInitialized && !init()) return false;

  int status = luaL_dostring(L, script.c_str());
  if (status != LUA_OK) {
    const char* err = lua_tostring(L, -1);
    LOG_ERR("ZLUA", "Lua runtime error: %s", err ? err : "unknown");
    lua_pop(L, 1);
    return false;
  }
  return true;
}

bool ZLuaEngine::runFile(const std::string& filePath) {
  if (!isInitialized && !init()) return false;

  HalStorage storage;
  auto f = storage.open(filePath.c_str(), O_RDONLY);
  if (!f || !f.isOpen()) {
    LOG_ERR("ZLUA", "Cannot open Lua script file: %s", filePath.c_str());
    return false;
  }

  size_t size = f.fileSize();
  if (size == 0) {
    LOG_ERR("ZLUA", "Lua script file is empty: %s", filePath.c_str());
    f.close();
    return false;
  }

  std::vector<char> buffer(size + 1);
  size_t bytesRead = f.read(buffer.data(), size);
  buffer[bytesRead] = '\0';
  f.close();

  int loadStatus = luaL_loadbuffer(L, buffer.data(), bytesRead, filePath.c_str());
  if (loadStatus != LUA_OK) {
    const char* err = lua_tostring(L, -1);
    LOG_ERR("ZLUA", "Lua syntax error in (%s): %s", filePath.c_str(), err ? err : "unknown");
    lua_pop(L, 1);
    return false;
  }

  int runStatus = lua_pcall(L, 0, LUA_MULTRET, 0);
  if (runStatus != LUA_OK) {
    const char* err = lua_tostring(L, -1);
    LOG_ERR("ZLUA", "Lua execution error in (%s): %s", filePath.c_str(), err ? err : "unknown");
    lua_pop(L, 1);
    return false;
  }

  return true;
}

bool ZLuaEngine::callFunction(const char* funcName) {
  if (!L) return false;

  lua_getglobal(L, funcName);
  if (!lua_isfunction(L, -1)) {
    lua_pop(L, 1);
    return false;
  }

  int status = lua_pcall(L, 0, 0, 0);
  if (status != LUA_OK) {
    const char* err = lua_tostring(L, -1);
    LOG_ERR("ZLUA", "Lua error in %s(): %s", funcName, err ? err : "unknown");
    lua_pop(L, 1);
    return false;
  }
  return true;
}

bool ZLuaEngine::callInputHandler(const char* key, const char* eventType, bool& outHandled) {
  outHandled = false;
  if (!L) return false;

  lua_getglobal(L, "onInput");
  if (!lua_isfunction(L, -1)) {
    lua_pop(L, 1);
    return false;
  }

  lua_pushstring(L, key);
  lua_pushstring(L, eventType);
  int status = lua_pcall(L, 2, 1, 0);
  if (status != LUA_OK) {
    const char* err = lua_tostring(L, -1);
    LOG_ERR("ZLUA", "Lua error in onInput(): %s", err ? err : "unknown");
    lua_pop(L, 1);
    return false;
  }

  outHandled = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return true;
}
