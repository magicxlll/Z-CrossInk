#pragma once
#include "ZPluginTypes.h"
#include <string>

class ZLuaPlugin : public ZPlugin {
private:
  ZPluginManifest manifest;

public:
  explicit ZLuaPlugin(ZPluginManifest manifest);
  virtual ~ZLuaPlugin() = default;

  const ZPluginManifest& getManifest() const override { return manifest; }
  bool init() override;
  void onEnable() override;
  void onDisable() override;

  bool onHomeMenuAction(ActivityManager& actMgr) override;
  bool onReaderMenuAction(ActivityManager& actMgr, const std::string& currentBook) override;
};
