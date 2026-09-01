#!/usr/bin/env bash
set -e

# ==============================================================================
# 🎮 Z-CROSSINK 1-CLICK DESKTOP SIMULATOR & TEST SUITE
# Target: Xteink X3 (528x792, Non-Touch, Physical Key Navigation)
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "========================================================"
echo "   🚀 LAUNCHING Z-CROSSINK X3 DESKTOP SIMULATOR         "
echo "========================================================"

# 1. Kiem tra thu vien do hoa SDL2
if ! command -v sdl2-config &> /dev/null; then
    echo "[!] Loi: Chua cai dat SDL2 tren may!"
    echo "    Vui long cai dat bang Homebrew: brew install sdl2"
    exit 1
fi

# 2. Chuan bi he thong tep ao (SD Card File System)
echo "[1/4] Chuan bi he thong the nho SD ao (fs_/)..."
mkdir -p fs_/plugins fs_/books fs_/.crosspoint
cp -rf plugins/* fs_/plugins/

echo "      [+] Da nạp cac plugin vao the SD ao:"
ls -1 fs_/plugins/ | sed 's/^/          - /'

# 3. Kiem tra cu phap cac plugin Lua
echo "[2/4] Kiem tra tinh toan ven cu phap Lua & JSON..."
for plugindir in plugins/*; do
    if [ -d "$plugindir" ]; then
        pname=$(basename "$plugindir")
        if [ -f "$plugindir/main.lua" ]; then
            luac -p "$plugindir/main.lua"
        fi
        if [ -f "$plugindir/manifest.json" ]; then
            python3 -m json.tool "$plugindir/manifest.json" > /dev/null
        fi
        echo "      [OK] Plugin '$pname' syntax verified."
    fi
done

# 4. Bien dich Native Simulator
echo "[3/4] Bien dich may ao Z-CrossInk (moi truong simulator-X3)..."
pio run -e simulator-X3

# 5. Khoi chay may ao
echo "[4/4] Khoi dong cua so mo phong SDL2 (X3 528x792)..."
echo "--------------------------------------------------------"
echo "  BAN PHIM DIEU KHIEN MAY DOC SACH X3:                 "
echo "    • Mui ten LEN / XUONG : Phim doc trang ben hong      "
echo "    • Mui ten TRAI / PHAI : Phim mat truoc Trai / Phai   "
echo "    • ENTER (Return)      : Phim CONFIRM (Chon)          "
echo "    • ESC (Escape)        : Phim BACK (Quay lai)         "
echo "    • P                   : Phim Nguon (Power / Sleep)   "
echo "--------------------------------------------------------"

./.pio/build/simulator-X3/program
