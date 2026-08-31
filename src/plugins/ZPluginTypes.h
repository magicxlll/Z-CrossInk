#pragma once
#include <string>
#include <vector>
#include <memory>
#include <functional>

enum class ZPluginCategory {
  HOME_APP,      // Appears on Home carousel/dashboard
  READER_TOOL,   // Injected into reader in-book menu
  NETWORK_SYNC,  // Background wireless sync service
  SYSTEM_TOOL    // Settings & system utilities
};

struct ZPluginManifest {
  std::string id;
  std::string name;
  std::string version;
  std::string author;
  std::string description;
  ZPluginCategory category = ZPluginCategory::HOME_APP;
  std::string entryScript; // Default: "main.lua"
  std::string iconName;    // Vector icon name or bitmap path
  bool enabled = true;
  int priority = 100;
  std::string pluginPath;  // Root directory on SD card
};

class ActivityManager;

class ZPlugin {
public:
  virtual ~ZPlugin() = default;
  virtual const ZPluginManifest& getManifest() const = 0;
  virtual bool init() = 0;
  virtual void onEnable() {}
  virtual void onDisable() {}
  virtual bool onHomeMenuAction(ActivityManager& actMgr) { return false; }
  virtual bool onReaderMenuAction(ActivityManager& actMgr, const std::string& currentBook) { return false; }
};
