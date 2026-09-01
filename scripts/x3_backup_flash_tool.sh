#!/usr/bin/env bash
# ==============================================================================
# 🛡️ XTEINK X3 (ESP32-C3) FIRMWARE BACKUP, FLASH & ROLLBACK TOOLKIT
# Safe 1-Click Operations for International Unlocked X3 Devices (16MB Flash)
# ==============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

BACKUP_DIR="$PROJECT_ROOT/backups"
mkdir -p "$BACKUP_DIR"

echo "=========================================================="
echo "   🛡️ XTEINK X3 HARDWARE SAFETY & FLASH TOOLKIT           "
echo "=========================================================="
echo "  1) [BACKUP] Sao lưu toàn bộ 16MB Flash gốc (Full ROM Dump)"
echo "  2) [FLASH]  Nạp Z-CrossInk Firmware vào thiết bị X3      "
echo "  3) [RESTORE] Khôi phục 100% Firmware gốc từ bản sao lưu "
echo "  4) [VERIFY] Kiểm tra cổng kết nối USB & Chip ESP32-C3   "
echo "  5) [EXIT]   Thoát                                       "
echo "=========================================================="

read -p "Vui lòng chọn thao tác (1-5): " choice

# Tự động tìm cổng Serial
detect_port() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        PORT=$(ls /dev/cu.usbserial* /dev/cu.usbmodem* 2>/dev/null | head -n 1 || true)
    else
        PORT=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -n 1 || true)
    fi
    if [ -z "$PORT" ]; then
        echo "[!] Không tìm thấy cổng USB của máy đọc sách X3!"
        echo "    Vui lòng cắm cáp USB-C kết nối máy tính với X3 và bật nguồn."
        exit 1
    fi
    echo "[+] Đã nhận diện cổng kết nối: $PORT"
}

case $choice in
    1)
        detect_port
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        BACKUP_FILE="$BACKUP_DIR/xteink_x3_full_backup_16mb_${TIMESTAMP}.bin"
        echo "[*] Đang tiến hành sao lưu toàn bộ 16MB Flash (Bootloader + NVS + System + Stock OS)..."
        esptool.py --chip esp32c3 --port "$PORT" --baud 921600 read_flash 0x0 0x1000000 "$BACKUP_FILE"
        echo "=========================================================="
        echo "✅ SAO LƯU THÀNH CÔNG 100%!"
        echo "📁 Tệp sao lưu an toàn: $BACKUP_FILE"
        echo "💡 Giữ tệp này để có thể khôi phục thiết bị về trạng thái gốc bất kỳ lúc nào."
        echo "=========================================================="
        ;;
    2)
        detect_port
        FW_BIN="$PROJECT_ROOT/dist/z-crossink-x3-v1.5.1.bin"
        if [ ! -f "$FW_BIN" ]; then
            echo "[*] Chưa có tệp dist, đang biên dịch firmware Z-CrossInk X3..."
            pio run -e default
            cp .pio/build/default/firmware.bin "$FW_BIN"
        fi
        echo "[*] Nạp Firmware Z-CrossInk vào phân vùng OTA của X3..."
        pio run -e default -t upload --upload-port "$PORT"
        echo "=========================================================="
        echo "✅ NẠP FIRMWARE Z-CROSSINK THÀNH CÔNG!"
        echo "=========================================================="
        ;;
    3)
        detect_port
        echo "Danh sách các bản sao lưu có sẵn trong thư mục backups/:"
        ls -la "$BACKUP_DIR"/*.bin 2>/dev/null || true
        echo ""
        read -p "Nhập đường dẫn đầy đủ của tệp .bin sao lưu cần khôi phục: " RESTORE_FILE
        if [ ! -f "$RESTORE_FILE" ]; then
            echo "[!] Tệp không tồn tại: $RESTORE_FILE"
            exit 1
        fi
        read -p "CẢNH BÁO: Thao tác này sẽ ghi đè 16MB Flash về bản sao lưu. Tiếp tục? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo "[*] Đang khôi phục toàn bộ 16MB Flash từ bản sao lưu..."
            esptool.py --chip esp32c3 --port "$PORT" --baud 921600 write_flash 0x0 "$RESTORE_FILE"
            echo "=========================================================="
            echo "✅ KHÔI PHỤC 100% NGUYÊN BẢN THÀNH CÔNG!"
            echo "=========================================================="
        fi
        ;;
    4)
        detect_port
        echo "[*] Đọc thông tin chip ESP32-C3 từ thiết bị..."
        esptool.py --chip esp32c3 --port "$PORT" chip_id
        esptool.py --chip esp32c3 --port "$PORT" flash_id
        ;;
    *)
        echo "Thoát."
        exit 0
        ;;
esac
