#pragma once
#include "../../activities/Activity.h"
#include "ZLuaEngine.h"
#include "../ZPluginTypes.h"
#include <memory>

class ZLuaActivity : public Activity {
private:
  ZPluginManifest manifest;
  std::shared_ptr<ZLuaEngine> engine;
  std::string scriptPath;

public:
  ZLuaActivity(GfxRenderer& renderer, MappedInputManager& mappedInput,
               const ZPluginManifest& manifest, const std::string& scriptPath);
  virtual ~ZLuaActivity() = default;

  void onEnter() override;
  void onExit() override;
  void loop() override;
  void render(RenderLock&& lock) override;
};
