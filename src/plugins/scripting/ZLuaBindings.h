#pragma once

struct lua_State;
class GfxRenderer;
class ActivityManager;
class MappedInputManager;

class ZLuaBindings {
public:
  static void registerAll(lua_State* L, GfxRenderer* renderer, ActivityManager* actMgr, MappedInputManager* inputMgr);
  static void setCurrentContext(GfxRenderer* renderer, ActivityManager* actMgr, MappedInputManager* inputMgr);
};
