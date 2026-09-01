#include "ZLuaPlugin.h"
#include "scripting/ZLuaActivity.h"
#include "../activities/ActivityManager.h"
#include <Logging.h>

ZLuaPlugin::ZLuaPlugin(ZPluginManifest manifest) : manifest(std::move(manifest)) {}

bool ZLuaPlugin::init() {
  LOG_INF("ZPLUGIN", "Loaded Lua plugin: %s v%s by %s",
          manifest.name.c_str(), manifest.version.c_str(), manifest.author.c_str());
  return true;
}

void ZLuaPlugin::onEnable() {
  manifest.enabled = true;
}

void ZLuaPlugin::onDisable() {
  manifest.enabled = false;
}

bool ZLuaPlugin::onHomeMenuAction(ActivityManager& actMgr) {
  std::string fullEntryPath = manifest.pluginPath + "/" + manifest.entryScript;
  LOG_INF("ZPLUGIN", "Launching Lua Home Activity: %s", fullEntryPath.c_str());

  actMgr.pushActivity(std::make_unique<ZLuaActivity>(actMgr.getRenderer(), actMgr.getMappedInput(), manifest, fullEntryPath));
  return true;
}

bool ZLuaPlugin::onReaderMenuAction(ActivityManager& actMgr, const std::string& currentBook) {
  return false;
}
