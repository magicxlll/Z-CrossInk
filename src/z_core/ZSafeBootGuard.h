#pragma once
#include <cstdint>

class ZSafeBootGuard {
public:
  static void init();
  static bool checkAndArmSafeMode();
  static bool isSafeMode();
  static void notifyBootSuccess();
  static void recordCrash();
  static void clearSafeMode();
};
