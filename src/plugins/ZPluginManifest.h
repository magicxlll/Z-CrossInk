#pragma once
#include "ZPluginTypes.h"
#include <string>

class ZPluginManifestParser {
public:
  static bool parse(const std::string& jsonContent, ZPluginManifest& outManifest);
  static bool loadFromFile(const std::string& filePath, ZPluginManifest& outManifest);
};
