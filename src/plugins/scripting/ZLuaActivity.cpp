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
  ZLuaBindings::setCurrentContext(&renderer, &activityManager, &mappedInput);

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
  ZLuaBindings::setCurrentContext(&renderer, &activityManager, &mappedInput);
  if (engine) {
    engine->callFunction("onRender");
  }
}

void ZLuaActivity::loop() {
  // Input handling is mapped from physical buttons
  if (mappedInput.wasReleased(MappedInputManager::Button::Back)) {
    bool handled = false;
    if (engine && engine->callInputHandler("BACK", "RELEASE", handled) && handled) {
      requestUpdate();
      return;
    }
    // Default: return home on back if unhandled
    finish();
    return;
  }

  if (mappedInput.wasReleased(MappedInputManager::Button::Confirm)) {
    bool handled = false;
    if (engine && engine->callInputHandler("CONFIRM", "RELEASE", handled) && handled) {
      requestUpdate();
      return;
    }
  }

  if (mappedInput.wasReleased(MappedInputManager::Button::Left)) {
    bool handled = false;
    if (engine && engine->callInputHandler("LEFT", "RELEASE", handled) && handled) {
      requestUpdate();
      return;
    }
  }

  if (mappedInput.wasReleased(MappedInputManager::Button::Right)) {
    bool handled = false;
    if (engine && engine->callInputHandler("RIGHT", "RELEASE", handled) && handled) {
      requestUpdate();
      return;
    }
  }

  if (mappedInput.wasReleased(MappedInputManager::Button::Up) ||
      mappedInput.wasReleased(MappedInputManager::Button::PageBack)) {
    bool handled = false;
    if (engine && engine->callInputHandler("UP", "RELEASE", handled) && handled) {
      requestUpdate();
      return;
    }
  }

  if (mappedInput.wasReleased(MappedInputManager::Button::Down) ||
      mappedInput.wasReleased(MappedInputManager::Button::PageForward)) {
    bool handled = false;
    if (engine && engine->callInputHandler("DOWN", "RELEASE", handled) && handled) {
      requestUpdate();
      return;
    }
  }
}
