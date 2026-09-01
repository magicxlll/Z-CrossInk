#include "ZPluginManifest.h"
#include <ArduinoJson.h>
#include <HalStorage.h>
#include <Logging.h>

bool ZPluginManifestParser::parse(const std::string& jsonContent, ZPluginManifest& outManifest) {
  if (jsonContent.empty()) {
    return false;
  }

  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, jsonContent);
  if (error) {
    LOG_ERR("ZPLUGIN", "Manifest JSON parse failed: %s", error.c_str());
    return false;
  }

  outManifest.id = doc["id"] | "";
  outManifest.name = doc["name"] | "";
  outManifest.version = doc["version"] | "1.0.0";
  outManifest.author = doc["author"] | "Community";
  outManifest.description = doc["description"] | "";
  outManifest.entryScript = doc["entry"] | "main.lua";
  outManifest.iconName = doc["icon"] | "book";
  outManifest.enabled = doc["enabled"] | true;
  outManifest.priority = doc["priority"] | 100;

  std::string cat = doc["category"] | "home";
  if (cat == "reader" || cat == "READER_TOOL") {
    outManifest.category = ZPluginCategory::READER_TOOL;
  } else if (cat == "sync" || cat == "NETWORK_SYNC") {
    outManifest.category = ZPluginCategory::NETWORK_SYNC;
  } else if (cat == "system" || cat == "SYSTEM_TOOL") {
    outManifest.category = ZPluginCategory::SYSTEM_TOOL;
  } else {
    outManifest.category = ZPluginCategory::HOME_APP;
  }

  return !outManifest.id.empty() && !outManifest.name.empty();
}

bool ZPluginManifestParser::loadFromFile(const std::string& filePath, ZPluginManifest& outManifest) {
  HalStorage storage;
  if (!storage.exists(filePath.c_str())) {
    return false;
  }

  auto file = storage.open(filePath.c_str(), O_RDONLY);
  if (!file) {
    LOG_ERR("ZPLUGIN", "Failed to open manifest file: %s", filePath.c_str());
    return false;
  }

  std::string content;
  content.reserve(file.size());
  char buf[256];
  while (file.available()) {
    size_t n = file.read((uint8_t*)buf, sizeof(buf));
    if (n > 0) {
      content.append(buf, n);
    }
  }
  file.close();

  bool success = parse(content, outManifest);
  if (success) {
    // Determine plugin root path
    size_t lastSlash = filePath.find_last_of('/');
    if (lastSlash != std::string::npos) {
      outManifest.pluginPath = filePath.substr(0, lastSlash);
    }
  }
  return success;
}
