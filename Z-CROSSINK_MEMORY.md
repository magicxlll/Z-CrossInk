# 🧠 Z-CROSSINK & Z-TRUYEN PLUGIN ECOSYSTEM — MASTER PROJECT MEMORY

> **QUY TẮC BẮT BUỘC DÀNH CHO AI AGENT KHI MỞ PHIÊN MỚI:**
> 1. Đọc kỹ tài liệu này trước tiên để nắm bắt 100% kiến trúc, tiến độ và quy chuẩn an toàn.
> 2. Đọc tài liệu đặc tả gốc: `docs/Z-CrossInk_Master_Engineering_Safety_And_Plugin_Spec_V1.md`.
> 3. **Tuyệt đối tuân thủ ranh giới an toàn**: Không sửa đổi Bootloader, Partition table, OTA logic hay driver phần cứng EPD.
> 4. Nhánh làm việc chính: `main` (trên repo `git@github.com:magicxlll/Z-CrossInk.git`).
> 5. Giữ nguyên sự độc lập giữa dự án Firmware `Z-CrossInk` (trong thư mục `crossink_source/`) và dự án ứng dụng di động `Z-Truyen` (ở thư mục gốc).

---

## 1. 📌 TỔNG QUAN DỰ ÁN (PROJECT OVERVIEW)

- **Tên dự án:** Z-CrossInk (Z-Truyen CrossInk E-ink Edition)
- **Mã nguồn gốc (Upstream):** [`uxjulia/CrossInk`](https://github.com/uxjulia/CrossInk) (nhánh `release/v1.5.1` & `main`)
- **Kho lưu trữ Fork chính thức:** [`magicxlll/Z-CrossInk`](https://github.com/magicxlll/Z-CrossInk.git)
- **Thiết bị mục tiêu:** Máy đọc sách **Xteink X3** (ESP32-C3 RISC-V SoC, Màn hình E-ink đơn sắc 528x792, Phiên bản quốc tế USB-Unlocked).
- **Mục tiêu cốt lõi:**
  1. Tích hợp sâu cổng đọc tiểu thuyết **Z-Truyen** vào máy đọc sách X3.
  2. Xây dựng **Hệ sinh thái Plugin động (Z-Plugin Engine)** có thể cài đặt/gỡ bỏ trực tiếp từ thẻ nhớ SD (`/plugins/`) mà **không cần nạp lại Firmware (No Reflash)**.
  3. Duy trì **khả năng đồng bộ 100% với các bản cập nhật tương lai của CrossInk gốc** (v1.5.2, v1.6.0...) nhờ cơ chế can thiệp tối thiểu (Minimal Seams / Diff Budget < 100 LOC).
  4. **An toàn phần cứng tuyệt đối (Zero Brick Risk)**: Cách ly hoàn toàn tầng ứng dụng Plugin khỏi phần cứng nhạy cảm. Tương thích 100% với công cụ cứu hộ khẩn cấp **CrossPoint Escape Hatch**.

---

## 2. 🏗️ KIẾN TRÚC HỆ THỐNG (SYSTEM ARCHITECTURE)

```text
                           Z-CROSSINK FIRMWARE
┌──────────────────────────────────────────────────────────────────────────┐
│                          UPSTREAM CROSSINK BASE                          │
│                                                                          │
│   Bootloader  •  Partition Table  •  HAL  •  EPD Display Driver          │
│   PowerManager  •  SdFat Storage  •  Native Epub Reader (ReaderActivity) │
│                                                                          │
├──────────────────────── Z-CrossInk Extension Layer ──────────────────────┤
│                                                                          │
│  [ZSafeBootGuard]   ──> Two-Stage Launch Confirmation & Safe-Mode Guard  │
│  [ZPluginManager]   ──> SD Scanner (/plugins/ & /.crosspoint/plugins/)    │
│  [ZPluginManifest]  ──> Manifest JSON Parser & Capability Validator      │
│  [ZLuaActivity]     ──> CrossInk Activity Adapter (Lifecycle Hook)       │
│  [ZLuaEngine]       ──> Sandboxed Lua 5.4.7 VM (Custom Memory Allocator) │
│  [ZLuaBindings]     ──> ZInk.* API Facade (Display, Input, Storage, etc.)│
│                                                                          │
├─────────────────────────── SD Card Plugins ──────────────────────────────┤
│  /plugins/                                                               │
│    ├── ztruyen/        -> Cổng truyện online, đọc tiếp, cào web & KOSync │
│    ├── viet_dict/      -> Từ điển Việt - Anh offline tra cứu nhanh       │
│    ├── sudoku/         -> Game giải đố Sudoku Zen 9x9 tương tác phím    │
│    ├── lunar_calendar/ -> Lịch vạn niên, âm lịch, can chi, danh ngôn     │
│    ├── system_info/    -> Chẩn đoán phần cứng, pin, uptime, heap RAM     │
│    └── hello/          -> Plugin tham chiếu chuẩn tối giản (Phase P1)    │
│                                                                          │
├────────────────────────── SD Card Books Data ────────────────────────────┤
│  /Books/ZTruyen/       -> Lưu trữ các tệp tiểu thuyết EPUB tải về        │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. 📂 DANH MỤC TÀI LIỆU KỸ THUẬT QUAN TRỌNG CẦN ĐỌC

| Tệp tài liệu | Vị trí | Tóm tắt nội dung |
| :--- | :--- | :--- |
| **`Z-CrossInk Master Spec v1.0`** | `docs/Z-CrossInk_Master_Engineering_Safety_And_Plugin_Spec_V1.md` | **Tài liệu gốc tối cao**: Quy chuẩn kỹ thuật, ngân sách diff, ranh giới an toàn phần cứng, lộ trình các pha P0 $\rightarrow$ P9. |
| **`Phase P0 Reality Audit`** | `docs/PHASE_P0_REALITY_AUDIT.md` | Báo cáo kiểm toán toàn bộ hệ thống (`EXISTING / PARTIAL / PROPOSED / SAFE`). |
| **`Phase P0 Upstream Diff`** | `docs/PHASE_P0_UPSTREAM_DIFF.md` | Báo cáo chi tiết các file can thiệp vào CrossInk gốc (~86 LOC) và cơ chế rebase. |
| **`Phase P0 Safety Review`** | `docs/PHASE_P0_SAFETY_REVIEW.md` | Đánh giá an toàn phần cứng và quy trình khôi phục khẩn cấp Escape Hatch. |
| **`Z-Plugin Specification v1.0`** | `docs/Z_PLUGIN_SPEC.md` | Đặc tả chi tiết chuẩn Plugin cộng đồng: `manifest.json`, bộ API `ZInk.*`, vòng đời `onInit/onEnter/onRender/onInput/onExit`. |
| **`Z-Plugin Developer Guide`** | `docs/Z_PLUGIN_DEVELOPER_GUIDE.md` | Sổ tay hướng dẫn lập trình plugin mẫu cho nhà phát triển bên thứ ba. |

---

## 4. 🚀 TIẾN ĐỘ ĐÃ HOÀN THÀNH (ACCOMPLISHED WORK)

### A. Hạ Tầng Cốt Lõi (Core Infrastructure)
1. **Quét & Nạp Plugin Tự Động (`ZPluginManager`)**: Tự động duyệt thư mục `/plugins/` trên thẻ nhớ SD, phân tích `manifest.json`, nạp động toàn bộ plugin vào Menu chính của màn hình Home (`HomeActivity.cpp`).
2. **Máy Ảo Script An Toàn (`ZLuaEngine`)**:
   - Tích hợp Lua 5.4.7 chuẩn C89/C99.
   - Vô hiệu hóa các thư viện nguy hiểm (`os`, `io`, `debug`, `package`).
   - Cấp phát bộ nhớ an toàn: **1 MB** trên Máy ảo Simulator và **96 KB** trên máy thật ESP32-C3.
3. **Bộ API ZInk Facade Hoàn Chỉnh (`ZLuaBindings`)**:
   - `ZInk.Display`: `clear()`, `drawText()`, `drawRect()`, `drawLine()`, `getWidth()`, `getHeight()`, `refresh()`.
   - `ZInk.Input`: Bắt các sự kiện phím vật lý `UP`, `DOWN`, `LEFT`, `RIGHT`, `CONFIRM`, `BACK`, `PAGE_PREV`, `PAGE_NEXT`.
   - `ZInk.Storage`: `readFile()`, `writeFile()`, `exists()` kèm bộ lọc bảo vệ chống tấn công `isSafePath` (chặn `..`).
   - `ZInk.System`: `getBatteryPercent()`, `getBatteryVoltage()`, `getFreeHeap()`, `getUptime()`, `getDeviceModel()`.
   - `ZInk.UI`: `popView()` thoát plugin an toàn về Home.
   - `ZInk.Reader`: `openBook(path)` mở trực tiếp trình đọc gốc CrossInk Reader.
   - `ZInk.Http`: `get()`, `post()` cho kết nối mạng.
4. **Hệ Thống Phòng Vệ Đa Tầng (`ZSafeBootGuard`)**:
   - Kiểm tra quyền hạn runtime (Runtime Permission Check) trước khi thực thi lệnh gọi nhạy cảm.
   - Cơ chế xác nhận khởi động 2 bước (`onPluginLaunchStart` $\rightarrow$ `onPluginLaunchStable` $\rightarrow$ `onPluginExit`).
   - Tự động ngắt plugin và chuyển sang Safe Mode nếu phát hiện crash 3 lần liên tiếp.
   - Hiển thị màn hình báo lỗi trực quan (Visual Error Screen) nếu plugin bị lỗi cú pháp, không bao giờ để máy bị treo màn hình trắng.

### B. Kho 6 Plugin Chuẩn Mực Đã Hoàn Thiện
1. 📚 **Z-Truyen Pro (`plugins/ztruyen/`)**: Cổng truyện thông minh đa kênh (Kệ sách offline, Kho truyện online, Bộ chuyển đổi 5 nguồn cào + OPDS Bridge, Bảng điều khiển KOSync Cloud 2 chiều).
2. 📖 **Từ Điển Việt - Anh (`plugins/viet_dict/`)**: Tra cứu từ vựng offline song ngữ, tích hợp thuật toán ngắt dòng thông minh (`wrapLines`).
3. 🔢 **Sudoku Zen E-ink (`plugins/sudoku/`)**: Trò chơi giải đố 9x9 với phím điều hướng D-pad.
4. 📅 **Lịch Vạn Niên & Âm Lịch (`plugins/lunar_calendar/`)**: Xem can chi, ngày hoàng đạo, tiết khí và danh ngôn.
5. ⚡ **Chẩn Đoán Phần Cứng (`plugins/system_info/`)**: Xem trạng thái pin Li-Po, bộ nhớ RAM, uptime, thông tin phần cứng X3.
6. 🧩 **Hello World Reference (`plugins/hello/`)**: Plugin tham chiếu chuẩn tối giản theo Phase P1.

---

## 5. 🛠️ HƯỚNG DẪN BIÊN DỊCH VÀ KIỂM THỬ (BUILD & TEST)

Tất cả các lệnh thực hiện trong thư mục `crossink_source/`:

### 1. Kích hoạt máy ảo Desktop (1-Click Simulator)
```bash
cd /Users/vietph/StudioProjects/Z-Truyen/crossink_source
./scripts/run_z_simulator.sh
```

### 2. Biên dịch bản Firmware Release cho thiết bị X3 (ESP32-C3)
```bash
pio run -e default
```
*Tệp binary hoàn chỉnh sau khi build:* `.pio/build/default/firmware.bin` $\rightarrow$ copy vào `dist/z-crossink-x3-v1.5.1.bin`.

### 3. Đồng bộ với upstream CrossInk khi có bản mới (v1.5.2+)
```bash
./scripts/z_sync_upstream.sh
```

---

## 6. 🎯 KẾ HOẠCH PHÁT TRIỂN TIẾP THEO (NEXT STEPS)

Khi tiếp tục phát triển ở các phiên tiếp theo, AI Agent sẽ tập trung:
1. **Nâng cấp ZTruyenCore Streaming Scraper**:
   - Hiện thực hóa module cào truyện trực tiếp qua Wi-Fi bằng C++ native kết hợp Lua orchestration.
   - Bộ đóng gói EPUB nhẹ trực tiếp trên thẻ nhớ SD `/Books/ZTruyen/` theo từng tập (Volume 50 chương/tập).
2. **Kiểm thử E2E KOSync Cloud**:
   - Kết nối trực tiếp máy ảo/máy thật X3 với server đồng bộ `http://sync.ztruyen.vn` và app Android Z-Truyen.
3. **Quy trình kiểm thử vật lý an toàn trên máy thật X3**:
   - Thực hiện backup dump flash đầy đủ bằng `scripts/x3_backup_flash_tool.sh` trước khi flash firmware lên thiết bị thật.

---
*Bản ghi nhớ được tạo và đồng bộ tự động vào ngày 01/09/2026.*
