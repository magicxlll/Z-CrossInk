#pragma once

struct lua_State;
class GfxRenderer;
class ActivityManager;
class MappedInputManager;

struct ZPluginManifest;

class ZLuaBindings {
public:
  static void registerAll(lua_State* L, GfxRenderer* renderer, ActivityManager* actMgr, MappedInputManager* inputMgr);
  static void setCurrentContext(GfxRenderer* renderer, ActivityManager* actMgr, MappedInputManager* inputMgr, const ZPluginManifest* manifest = nullptr);
};
