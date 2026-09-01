#include "ZSafeBootGuard.h"
#include <HalStorage.h>
#include <HalGPIO.h>
#include <Logging.h>
#include "ZConfig.h"

#ifndef SIMULATOR
#include <esp_attr.h>
#else
#define RTC_DATA_ATTR
#endif

namespace {
RTC_DATA_ATTR uint32_t rtcBootCount = 0;
RTC_DATA_ATTR uint32_t rtcCrashCount = 0;
bool g_isSafeMode = false;
}

void ZSafeBootGuard::init() {
  rtcBootCount++;
  
  // 1. Check RTC consecutive crash counter
  if (rtcCrashCount >= ZConfig::SAFE_BOOT_CRASH_THRESHOLD) {
    g_isSafeMode = true;
    LOG_ERR("ZSAFE", "Triple crash threshold reached (%u)! Enforcing Safe Mode.", rtcCrashCount);
    return;
  }

  // 2. Check Hardware Key (Back button held during power-on wake)
  #ifndef SIMULATOR
  if (gpio.isPressed(HalGPIO::BTN_BACK)) {
    g_isSafeMode = true;
    LOG_INF("ZSAFE", "Back button held during power-on. Safe Mode activated by user.");
    return;
  }
  #endif

  // 3. Check SD card explicit flag file
  HalStorage storage;
  if (storage.exists(ZConfig::SAFE_MODE_FLAG_PATH)) {
    g_isSafeMode = true;
    LOG_INF("ZSAFE", "Safe Mode flag file found on SD card: %s", ZConfig::SAFE_MODE_FLAG_PATH);
  }
}

bool ZSafeBootGuard::isSafeMode() {
  return g_isSafeMode;
}

void ZSafeBootGuard::notifyBootSuccess() {
  rtcCrashCount = 0; // Reset crash counter once UI is running stably
}

void ZSafeBootGuard::recordCrash() {
  rtcCrashCount++;
}

void ZSafeBootGuard::clearSafeMode() {
  g_isSafeMode = false;
  rtcCrashCount = 0;
  HalStorage storage;
  if (storage.exists(ZConfig::SAFE_MODE_FLAG_PATH)) {
    storage.remove(ZConfig::SAFE_MODE_FLAG_PATH);
  }
}
