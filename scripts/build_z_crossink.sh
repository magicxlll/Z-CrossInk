#!/usr/bin/env bash
set -e

# ========================================================
# Z-CrossInk Automated Firmware Build Script
# Target: Xteink X3 & X4 (ESP32-C3 / 16MB Flash)
# ========================================================

echo "========================================================"
echo "   BUILDING Z-CROSSINK PRO FIRMWARE (MODULAR FORK)      "
echo "========================================================"

mkdir -p dist

# 1. Check PlatformIO build environment
if command -v pio >/dev/null 2>&1; then
  echo "[1/3] Running PlatformIO firmware compile..."
  pio run -e default
  
  if [ -f ".pio/build/default/firmware.bin" ]; then
    cp .pio/build/default/firmware.bin dist/z-crossink-x3-v1.5.1.bin
    echo "[2/3] Firmware generated: dist/z-crossink-x3-v1.5.1.bin"
  fi
else
  echo "[1/3] PlatformIO CLI not found in PATH. Skipping direct flash compilation."
fi

# 2. Package Z-Truyen default plugin
echo "[3/3] Packaging Z-Truyen plugin distribution..."
mkdir -p dist/plugins/ztruyen
cp -r plugins/ztruyen/* dist/plugins/ztruyen/

echo "========================================================"
echo "  BUILD & PACKAGING COMPLETED!                          "
echo "  Distribution folder: dist/                           "
echo "========================================================"
