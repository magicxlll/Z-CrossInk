#include "ZPluginManager.h"
#include "ZPluginManifest.h"
#include "ZLuaPlugin.h"
#include "../z_core/ZSafeBootGuard.h"
#include <HalStorage.h>
#include <Logging.h>
#include <algorithm>

ZPluginManager& ZPluginManager::getInstance() {
  static ZPluginManager instance;
  return instance;
}

void ZPluginManager::init() {
  if (initialized) return;

  if (ZSafeBootGuard::isSafeMode()) {
    LOG_WRN("ZPLUGIN", "Safe Mode is active. Skipping dynamic plugin scanning.");
    initialized = true;
    return;
  }

  reload();
  initialized = true;
}

void ZPluginManager::scanDirectory(const char* dirPath) {
  if (!storage.exists(dirPath)) {
    return;
  }

  auto dir = storage.open(dirPath);
  if (!dir || !dir.isDirectory()) {
    return;
  }

  while (true) {
    auto entry = dir.openNextFile();
    if (!entry) break;

    if (entry.isDirectory()) {
      std::string subDirName = entry.name();
      std::string manifestPath = std::string(dirPath) + "/" + subDirName + "/manifest.json";

      if (storage.exists(manifestPath.c_str())) {
        ZPluginManifest manifest;
        if (ZPluginManifestParser::loadFromFile(manifestPath, manifest)) {
          if (manifest.enabled) {
            auto plugin = std::make_shared<ZLuaPlugin>(manifest);
            if (plugin->init()) {
              plugins.push_back(plugin);
            }
          }
        }
      }
    }
    entry.close();
  }
  dir.close();
}

void ZPluginManager::reload() {
  plugins.clear();
  scanDirectory(ZConfig::PLUGINS_PRIMARY_DIR);
  scanDirectory(ZConfig::PLUGINS_SD_DIR);

  // Sort plugins by priority
  std::sort(plugins.begin(), plugins.end(), [](const std::shared_ptr<ZPlugin>& a, const std::shared_ptr<ZPlugin>& b) {
    return a->getManifest().priority < b->getManifest().priority;
  });

  LOG_INF("ZPLUGIN", "Total plugins registered: %zu", plugins.size());
}

std::vector<std::shared_ptr<ZPlugin>> ZPluginManager::getHomePlugins() const {
  std::vector<std::shared_ptr<ZPlugin>> list;
  for (const auto& p : plugins) {
    if (p->getManifest().enabled && p->getManifest().category == ZPluginCategory::HOME_APP) {
      list.push_back(p);
    }
  }
  return list;
}

std::vector<std::shared_ptr<ZPlugin>> ZPluginManager::getReaderPlugins() const {
  std::vector<std::shared_ptr<ZPlugin>> list;
  for (const auto& p : plugins) {
    if (p->getManifest().enabled && p->getManifest().category == ZPluginCategory::READER_TOOL) {
      list.push_back(p);
    }
  }
  return list;
}

std::vector<std::shared_ptr<ZPlugin>> ZPluginManager::getSyncPlugins() const {
  std::vector<std::shared_ptr<ZPlugin>> list;
  for (const auto& p : plugins) {
    if (p->getManifest().enabled && p->getManifest().category == ZPluginCategory::NETWORK_SYNC) {
      list.push_back(p);
    }
  }
  return list;
}

std::shared_ptr<ZPlugin> ZPluginManager::getPluginById(const std::string& id) const {
  for (const auto& p : plugins) {
    if (p->getManifest().id == id) {
      return p;
    }
  }
  return nullptr;
}

bool ZPluginManager::setPluginEnabled(const std::string& id, bool enabled) {
  auto p = getPluginById(id);
  if (p) {
    if (enabled) p->onEnable();
    else p->onDisable();
    return true;
  }
  return false;
}
