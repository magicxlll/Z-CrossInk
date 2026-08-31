#include "ZLuaActivity.h"
#include "ZLuaBindings.h"
#include <Logging.h>

ZLuaActivity::ZLuaActivity(GfxRenderer& renderer, MappedInputManager& mappedInput,
                           const ZPluginManifest& manifest, const std::string& scriptPath)
    : Activity("ZLuaActivity", renderer, mappedInput),
      manifest(manifest),
      scriptPath(scriptPath) {
  engine = std::make_shared<ZLuaEngine>();
}

void ZLuaActivity::onEnter() {
  Activity::onEnter();
  ZLuaBindings::setCurrentContext(&renderer, nullptr, &mappedInput);

  if (engine->init()) {
    if (!scriptPath.empty()) {
      engine->runFile(scriptPath);
    }
    engine->callFunction("onEnter");
  }
  requestUpdate(true);
}

void ZLuaActivity::onExit() {
  if (engine) {
    engine->callFunction("onExit");
    engine->shutdown();
  }
  Activity::onExit();
}

void ZLuaActivity::render(RenderLock&& lock) {
  ZLuaBindings::setCurrentContext(&renderer, nullptr, &mappedInput);
  if (engine) {
    engine->callFunction("onRender");
  }
}

void ZLuaActivity::loop() {
  // Input handling is mapped from physical buttons
  if (mappedInput.wasBackPressed()) {
    bool handled = false;
    if (engine && engine->callInputHandler("BACK", "RELEASE", handled) && handled) {
      requestUpdate();
      return;
    }
    // Default: return home on back if unhandled
    finish();
    return;
  }

  if (mappedInput.wasConfirmPressed()) {
    bool handled = false;
    if (engine && engine->callInputHandler("CONFIRM", "RELEASE", handled) && handled) {
      requestUpdate();
      return;
    }
  }

  if (mappedInput.wasLeftPressed()) {
    bool handled = false;
    if (engine && engine->callInputHandler("LEFT", "RELEASE", handled) && handled) {
      requestUpdate();
      return;
    }
  }

  if (mappedInput.wasRightPressed()) {
    bool handled = false;
    if (engine && engine->callInputHandler("RIGHT", "RELEASE", handled) && handled) {
      requestUpdate();
      return;
    }
  }
}
