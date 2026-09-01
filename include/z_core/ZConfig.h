#pragma once
#include <cstdint>

#ifndef Z_CROSSINK_BUILD
#define Z_CROSSINK_BUILD 1
#endif

#define Z_CROSSINK_VERSION "1.5.1-zpro1"
#define Z_CROSSINK_CODENAME "Lotus"

namespace ZConfig {

// Dynamic plugin locations on SD card
constexpr const char* PLUGINS_PRIMARY_DIR = "/.crosspoint/plugins";
constexpr const char* PLUGINS_SD_DIR = "/plugins";
constexpr const char* SAFE_MODE_FLAG_PATH = "/.crosspoint/safemode.flag";

// Safety limits for embedded runtime & simulator
#if defined(SIMULATOR)
constexpr uint32_t MAX_PLUGIN_HEAP_BYTES = 1024 * 1024;    // 1MB max allocations for Desktop Simulator
#else
constexpr uint32_t MAX_PLUGIN_HEAP_BYTES = 96 * 1024;      // 96KB max allocations for ESP32-C3
#endif
constexpr uint8_t MAX_ACTIVE_PLUGINS = 12;                 // Max concurrent registered plugins
constexpr uint32_t SAFE_BOOT_CRASH_THRESHOLD = 3;          // 3 crashes trigger auto Safe-Mode

// Z-Truyen default integration endpoints
constexpr const char* DEFAULT_ZTRUYEN_LOCAL_PORT = "8080";
constexpr const char* DEFAULT_ZTRUYEN_KOSYNC_USER = "ztruyen";

} // namespace ZConfig
