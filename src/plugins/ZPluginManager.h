#pragma once
#include "ZPluginTypes.h"
#include <vector>
#include <memory>
#include <string>

class ActivityManager;

class ZPluginManager {
private:
  std::vector<std::shared_ptr<ZPlugin>> plugins;
  bool initialized = false;

  void scanDirectory(const char* dirPath);

public:
  static ZPluginManager& getInstance();

  void init();
  void reload();

  const std::vector<std::shared_ptr<ZPlugin>>& getAllPlugins() const { return plugins; }
  std::vector<std::shared_ptr<ZPlugin>> getHomePlugins() const;
  std::vector<std::shared_ptr<ZPlugin>> getReaderPlugins() const;
  std::vector<std::shared_ptr<ZPlugin>> getSyncPlugins() const;

  std::shared_ptr<ZPlugin> getPluginById(const std::string& id) const;
  bool setPluginEnabled(const std::string& id, bool enabled);
};
