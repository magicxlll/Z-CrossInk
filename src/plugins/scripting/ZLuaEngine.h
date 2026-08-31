#pragma once
#include <string>
#include <cstdint>
#include "ZConfig.h"

struct lua_State;

class ZLuaEngine {
private:
  lua_State* L = nullptr;
  size_t memoryAllocated = 0;
  bool isInitialized = false;

  static void* customAlloc(void* ud, void* ptr, size_t osize, size_t nsize);

public:
  ZLuaEngine();
  ~ZLuaEngine();

  bool init();
  void shutdown();

  bool runFile(const std::string& filePath);
  bool runString(const std::string& script);

  bool callFunction(const char* funcName);
  bool callInputHandler(const char* key, const char* eventType, bool& outHandled);

  size_t getMemoryUsage() const { return memoryAllocated; }
  lua_State* getState() { return L; }
};
