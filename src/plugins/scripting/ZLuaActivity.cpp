#include "ZLuaActivity.h"
#include "ZLuaBindings.h"
#include "../../fontIds.h"
#include "../../z_core/ZSafeBootGuard.h"
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
  ZSafeBootGuard::onPluginLaunchStart(manifest.id);
  ZLuaBindings::setCurrentContext(&renderer, &activityManager, &mappedInput, &manifest);

  if (engine->init()) {
    if (!scriptPath.empty()) {
      if (!engine->runFile(scriptPath)) {
        scriptLoaded = false;
        LOG_ERR("ZLUA", "Failed to load/execute script: %s", scriptPath.c_str());
      } else {
        scriptLoaded = true;
        engine->callFunction("onEnter");
        ZSafeBootGuard::onPluginLaunchStable(manifest.id);
      }
    }
  }
  requestUpdate(true);
}

void ZLuaActivity::onExit() {
  ZSafeBootGuard::onPluginExit(manifest.id);
  if (engine && scriptLoaded) {
    engine->callFunction("onExit");
    engine->shutdown();
  }
  Activity::onExit();
}

void ZLuaActivity::render(RenderLock&& lock) {
  ZLuaBindings::setCurrentContext(&renderer, &activityManager, &mappedInput, &manifest);
  if (engine && scriptLoaded) {
    engine->callFunction("onRender");
  } else {
    renderer.clearScreen();
    renderer.drawText(LEXENDDECA_14_FONT_ID, 30, 50, "Z-CROSSINK SCRIPT ENGINE");
    renderer.drawLine(20, 75, renderer.getScreenWidth() - 20, 75, 0);
    renderer.drawText(UI_12_FONT_ID, 30, 110, "Loi nap tap tin Plugin:");
    renderer.drawText(UI_10_FONT_ID, 30, 140, scriptPath.c_str());
    renderer.drawText(UI_10_FONT_ID, 30, 180, "Vui long kiem tra cu phap hoac bo nho RAM.");
    renderer.drawText(UI_10_FONT_ID, 30, renderer.getScreenHeight() - 50, "[Nhan BACK de thoat]");
  }
  renderer.displayBuffer();
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
