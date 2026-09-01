#pragma once
#include <cstdint>
#include <string>

class ZSafeBootGuard {
public:
  static void init();
  static bool checkAndArmSafeMode();
  static bool isSafeMode();
  static void notifyBootSuccess();
  static void recordCrash();
  static void clearSafeMode();

  // Two-stage launch confirmation & per-plugin containment
  static void onPluginLaunchStart(const std::string& pluginId);
  static void onPluginLaunchStable(const std::string& pluginId);
  static void onPluginExit(const std::string& pluginId);
  static bool isPluginDisabled(const std::string& pluginId);
};
