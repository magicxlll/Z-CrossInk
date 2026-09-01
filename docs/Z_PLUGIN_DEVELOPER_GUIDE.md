# 📖 Z-CROSSINK PLUGIN DEVELOPER GUIDE (Z-PLUGIN SPEC v1.0)
> **Cẩm Nang Kỹ Thuật Toàn Diện Dành Cho Nhà Phát Triển & Cộng Đồng Sáng Tạo Plugin Cho Máy Đọc Sách Z-CrossInk**

---

## 1. 🌟 TỔNG QUAN VỀ HỆ THỐNG Z-PLUGIN

**Z-CrossInk Plugin System** là nền tảng mở rộng phần mềm dạng module động (Dynamic Plugin Architecture) được thiết kế riêng cho các dòng máy đọc sách E-ink nhúng (tiêu biểu như **Xteink X3, X4** chạy vi điều khiển ESP32-C3).

Khác với các hệ điều hành thông thường yêu cầu phải biên dịch lại toàn bộ firmware mỗi khi thêm tính năng, Z-CrossInk cho phép người dùng và lập trình viên:
- **Cài đặt & Gỡ bỏ tức thì (Hot-Plug)**: Chỉ cần sao chép thư mục plugin vào thẻ nhớ SD (`/sdcard/plugins/` hoặc `/.crosspoint/plugins/`).
- **An toàn tuyệt đối (Zero-Brick Guarantee)**: Mã nguồn plugin chạy bên trong Sandbox Lua 5.4 bị cô lập bộ nhớ, không có quyền can thiệp vào các thanh ghi phần cứng (HAL) hay bootloader.
- **Tối ưu hóa chuyên sâu cho màn hình E-ink**: Toàn bộ hệ thống API vẽ đồ họa được thiết kế để kiểm soát tốc độ quét, khử bóng ma (ghosting) và hiển thị tương phản 1-bit / 4-bit sắc nét.

---

## 2. 🏛️ KIẾN TRÚC VẬN HÀNH BÊN DƯỚI (INTERNAL ARCHITECTURE)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THẺ NHỚ MICRO SD CARD                           │
│  /.crosspoint/plugins/  hoặc  /plugins/                                │
│   ├── ztruyen/        (manifest.json, main.lua, icon.bmp)              │
│   ├── viet_dict/      (manifest.json, main.lua, dict.dat)              │
│   ├── sudoku/         (manifest.json, main.lua)                        │
│   └── weather_clock/  (manifest.json, main.lua)                        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ (Tự động quét khi khởi động)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   Z-CROSSINK PLUGIN HOST RUNTIME                       │
│                                                                        │
│  ┌───────────────────────┐             ┌────────────────────────────┐  │
│  │    ZPluginManager     │             │     ZSafeBootGuard         │  │
│  │  • Quét tệp manifest  │             │  • Giữ Back = Safe Mode    │  │
│  │  • Đăng ký danh mục   │             │  • RTC Crash Loop Detect   │  │
│  └───────────┬───────────┘             └─────────────┬──────────────┘  │
│              │                                       │                 │
│              ▼                                       │                 │
│  ┌───────────────────────────────────────────────────┴──────────────┐  │
│  │            ZLuaEngine & Sandboxed Lua 5.4.7 VM                   │  │
│  │  • Cấp phát bộ nhớ an toàn (Heap Allocation Capped <= 32KB)      │  │
│  │  • Vòng đời sự kiện: onEnter, onRender, onInput, onExit          │  │
│  └──────────────────────────────────┬───────────────────────────────┘  │
│                                     │                                  │
│  ┌──────────────────────────────────┴───────────────────────────────┐  │
│  │                 C++ Native Bindings (ZInk.*)                     │  │
│  │  • ZInk.Display : Vẽ Text, Hình chữ nhật, Đường thẳng, Refresh   │  │
│  │  • ZInk.Input   : Bắt phím bấm Back, Confirm, Left, Right, Up/Down│  │
│  │  • ZInk.Storage : Đọc/Ghi/Kiểm tra tệp tin trên thẻ nhớ SD       │  │
│  │  • ZInk.System  : Đọc % Pin, Điện áp mV, RAM Heap, Uptime, Temp  │  │
│  │  • ZInk.UI      : Chuyển màn hình, Thoát về Menu chính           │  │
│  │  • ZInk.Reader  : Kích hoạt mở sách EPUB/TXT, Đồng bộ KOSync     │  │
│  └──────────────────────────────────┬───────────────────────────────┘  │
├─────────────────────────────────────┼──────────────────────────────────┤
│                                     ▼                                  │
│                 CROSSINK CORE HAL (BẤT BIẾN & AN TOÀN)                 │
│         FreeInkDisplay • HalStorage • InputManager • PowerManager      │
└────────────────────────────────────────────────────────────────────────┘
```

### Các Trụ Cột An Toàn Bộ Nhớ & Phần Cứng:
1. **Khống Chế Bộ Nhớ Độc Lập (32KB Heap Limit)**: Mỗi plugin khi khởi chạy được cấp một hạn mức Heap tối đa 32KB RAM thông qua hàm cấp phát `customAlloc`. Nếu script bị memory leak hoặc tạo bảng quá lớn, VM sẽ tự ngắt an toàn thay vì làm treo vi điều khiển ESP32-C3.
2. **Cooperative Event Loop**: Plugin hoạt động theo mô hình hướng sự kiện (Event-driven). Khi không có thao tác phím hay yêu cầu vẽ lại, CPU chuyển về trạng thái tiết kiệm pin (Light Sleep).
3. **Cơ Chế Thoát Hiểm Khẩn Cấp (Safe Mode)**: Nếu một plugin lỗi làm sập máy 3 lần liên tiếp, `ZSafeBootGuard` sẽ tự động vô hiệu hóa toàn bộ plugin trên thẻ SD, đưa thiết bị về giao diện tiêu chuẩn để người dùng xóa plugin lỗi.

---

## 3. 📂 CẤU TRÚC THƯ MỤC CỦA MỘT PLUGIN

Mỗi plugin là một thư mục nằm tại `/plugins/<plugin_id>/` hoặc `/.crosspoint/plugins/<plugin_id>/` trên thẻ nhớ SD:

```
plugins/my_plugin/
├── manifest.json       (Bắt buộc: Khai báo thông tin, quyền hạn, danh mục)
├── main.lua            (Bắt buộc: Mã nguồn chính thực thi logic ứng dụng)
├── icon.bmp            (Tùy chọn: Icon đơn sắc 48x48 hiển thị trên Home)
└── assets/             (Tùy chọn: Dữ liệu tĩnh, từ điển, ma trận game, font)
    ├── data.json
    └── levels.dat
```

---

## 4. 📝 ĐẶC TẢ TỆP MANIFEST.JSON

Tệp `manifest.json` chứa các siêu dữ liệu giúp Z-CrossInk nhận diện và phân loại ứng dụng:

```json
{
  "id": "sudoku_zen",
  "name": "Sudoku Zen E-ink",
  "version": "1.0.0",
  "author": "Z-Truyen Community",
  "description": "Trò chơi Sudoku rèn luyện trí tuệ với 4 cấp độ và lưu tiến trình.",
  "category": "HOME_APP",
  "entry": "main.lua",
  "icon": "grid",
  "priority": 10,
  "enabled": true
}
```

### Chi Tiết Các Trường:
- `id` *(chuỗi, bắt buộc)*: Định danh duy nhất của plugin (chỉ gồm chữ thường `a-z`, số `0-9`, dấu gạch dưới `_`).
- `name` *(chuỗi, bắt buộc)*: Tên hiển thị của ứng dụng trên màn hình E-ink.
- `version` *(chuỗi)*: Phiên bản dạng Semantic Versioning (`1.0.0`).
- `category` *(chuỗi)*: Danh mục tích hợp trong hệ thống:
  - `"HOME_APP"`: Xuất hiện trên băng chuyền ứng dụng màn hình chính (Home Menu).
  - `"READER_TOOL"`: Tích hợp vào menu tiện ích bên trong khi đang đọc sách.
  - `"NETWORK_SYNC"`: Chạy nền đồng bộ dịch vụ mạng hoặc Web Server.
  - `"SYSTEM_TOOL"`: Nằm trong mục Tiện ích & Cài đặt hệ thống.
- `entry` *(chuỗi)*: Tên tệp Lua điểm nạp (mặc định: `main.lua`).
- `priority` *(số)*: Thứ tự ưu tiên sắp xếp trên giao diện (số nhỏ đứng trước).

---

## 5. 🔄 VÒNG ĐỜI SỰ KIỆN CỦA PLUGIN (LIFECYCLE EVENTS)

Tệp `main.lua` có thể định nghĩa 4 hàm callback cốt lõi được hệ thống tự động gọi:

```lua
-- 1. Khi plugin được mở vào màn hình
function onEnter()
    print("Plugin khoi dong!")
    -- Khoi tao bien, load file save tu SD
end

-- 2. Khi he thong yeu cau ve lai man hinh E-ink
function onRender()
    -- Xoa man hinh va ve giao dien
    ZInk.Display.clear()
    ZInk.Display.drawText(20, 40, "XIN CHAO Z-CROSSINK", 14)
end

-- 3. Khi nguoi dung bam nut vat ly tren thiet bi
-- Cac nut: "BACK", "CONFIRM", "LEFT", "RIGHT", "UP", "DOWN"
-- Action: "PRESS", "RELEASE"
function onInput(button, action)
    if action == "RELEASE" then
        if button == "CONFIRM" then
            -- Xu ly hanh dong
            return true -- Tra ve true de bao da xu ly su kien
        elseif button == "BACK" then
            ZInk.UI.popView() -- Quay ve man hinh chinh
            return true
        end
    end
    return false
end

-- 4. Khi plugin dong de thoat ve Home hoac tat may
function onExit()
    -- Luu trang thai, dong tep tin
end
```

---

## 6. 📚 TRA CỨU ĐẦY ĐỦ API BINDING (`ZInk.*`)

### A. Nhóm Đồ Họa & Hiển Thị (`ZInk.Display`)
Toàn bộ tọa độ hiển thị được tính theo độ phân giải chuẩn của Xteink X3: **Width = 528 px, Height = 792 px** (Gốc tọa độ `(0,0)` ở góc trên bên trái).

| Hàm API | Tham số | Mô tả |
| :--- | :--- | :--- |
| `ZInk.Display.clear()` | *không có* | Xóa sạch toàn bộ Framebuffer về màu trắng |
| `ZInk.Display.drawText(x, y, text, size)` | `x, y, text, size` | Vẽ chuỗi văn bản UTF-8 tại tọa độ `(x, y)` với cỡ chữ `size` (10, 12, 14, 16) |
| `ZInk.Display.drawRect(x, y, w, h, filled)` | `x, y, w, h, filled` | Vẽ hình chữ nhật rỗng (`filled=false`) hoặc đặc đen (`filled=true`) |
| `ZInk.Display.drawLine(x1, y1, x2, y2)` | `x1, y1, x2, y2` | Vẽ đoạn thẳng nối 2 điểm |
| `ZInk.Display.getWidth()` | *không có* | Lấy chiều rộng màn hình (trả về `528`) |
| `ZInk.Display.getHeight()` | *không có* | Lấy chiều cao màn hình (trả về `792`) |

### B. Nhóm Tệp Tin & Lưu Trữ Thẻ Nhớ (`ZInk.Storage`)
Mọi đường dẫn tệp tin đều thao tác trực tiếp với thẻ nhớ Micro SD Card:

| Hàm API | Tham số | Giá trị trả về | Mô tả |
| :--- | :--- | :--- | :--- |
| `ZInk.Storage.readFile(path)` | `path` | `string` hoặc `nil` | Đọc toàn bộ nội dung tệp tin văn bản từ thẻ nhớ |
| `ZInk.Storage.writeFile(path, data)`| `path, data` | `boolean` | Ghi đè dữ liệu chuỗi vào tệp tin trên thẻ nhớ |
| `ZInk.Storage.exists(path)` | `path` | `boolean` | Kiểm tra sự tồn tại của tệp tin hoặc thư mục |

### C. Nhóm Đo Đạc & Telemetry Phần Cứng (`ZInk.System`)

| Hàm API | Giá trị trả về | Đơn vị | Mô tả |
| :--- | :--- | :--- | :--- |
| `ZInk.System.getBatteryPercent()` | `0 - 100` | `%` | Phần trăm dung lượng pin Li-Po còn lại |
| `ZInk.System.getBatteryVoltage()` | `3300 - 4200` | `mV` | Điện áp thực tế đo từ IC quản lý nguồn |
| `ZInk.System.isCharging()` | `true / false` | `bool` | Trạng thái cắm sạc cáp USB-C |
| `ZInk.System.getFreeHeap()` | `số nguyên` | `Bytes` | Dung lượng bộ nhớ RAM SRAM còn trống của ESP32 |
| `ZInk.System.getUptime()` | `số nguyên` | `Giây` | Thời gian thiết bị hoạt động từ lúc bật nguồn |

### D. Nhóm Điều Hướng & Trình Đọc Sách (`ZInk.UI` & `ZInk.Reader`)

| Hàm API | Tham số | Mô tả |
| :--- | :--- | :--- |
| `ZInk.UI.popView()` | *không có* | Đóng Activity hiện tại và quay về màn hình chính |
| `ZInk.Reader.openBook(path)` | `path` | Thoát khỏi plugin và trực tiếp mở tệp sách `.epub` / `.txt` vào trình đọc sách native |

---

## 7. 💡 BẢN THIẾT KẾ & TIỀM NĂNG PHÁT TRIỂN CÁC TÍNH NĂNG MỞ RỘNG

Máy đọc sách là một thiết bị di động tập trung cao độ vào trải nghiệm đọc, học tập và thư giãn nhẹ nhàng. Dưới đây là các ý tưởng plugin tiềm năng cùng giải pháp kỹ thuật cụ thể:

---

### 🌟 Nhóm 1: Tiện Ích Đời Sống & Bàn Làm Việc (Productivity & Desk Clock)

#### 1. 📅 Plugin Lịch Vạn Niên & Âm Lịch (Lunar Calendar & Daily Quote)
- **Ý tưởng**: Biến máy đọc sách thành một cuốn lịch để bàn E-ink thông minh. Hiển thị ngày dương, ngày âm, can chi, giờ hoàng đạo, tiết khí và mỗi ngày một câu danh ngôn đọc sách sâu sắc.
- **Giải pháp kỹ thuật**:
  - Tích hợp thuật toán chuyển đổi Dương lịch sang Âm lịch thuần túy bằng toán học (thuật toán thiên văn Hồ Ngọc Đức) viết bằng Lua (~3KB mã nguồn, chạy offline 100% không cần mạng).
  - Tệp `quotes.json` lưu sẵn 365 câu danh ngôn trên thẻ SD, tự động chọn câu tương ứng với ngày trong năm.

#### 2. ⛅ Plugin Đồng Hồ E-ink & Thời Tiết Đa Trạm (Weather Clock)
- **Ý tưởng**: Trạm thời tiết E-ink hiển thị dự báo thời tiết 3 ngày, nhiệt độ, độ ẩm, chất lượng không khí (AQI) và đồng hồ số lớn.
- **Giải pháp kỹ thuật**:
  - Kết nối Wi-Fi định kỳ 2 tiếng/lần để gọi Open-Meteo REST API (API miễn phí, không cần API Key, hỗ trợ định vị GPS theo tọa độ thành phố).
  - Lưu kết quả vào `/.crosspoint/weather_cache.json`. Khi ngắt Wi-Fi, màn hình vẫn hiển thị dữ liệu dự báo kết hợp đồng hồ RTC thời gian thực.

#### 3. 📰 Plugin Đọc Báo Nhanh / RSS Offline (Z-News Digest)
- **Ý tưởng**: Tải các bài báo tóm tắt từ các kênh tin tức uy tín (VnExpress, Tuổi Trẻ, BBC Tiếng Việt, Wikipedia Article of the Day) để đọc offline trên đường đi làm hoặc du lịch.
- **Giải pháp kỹ thuật**:
  - Script Lua kết nối Wi-Fi, tải feed RSS XML, bóc tách các thẻ `<item><title><description>`, làm sạch mã HTML thừa và lưu thành danh sách bài đọc ngắn phân trang rõ ràng trên E-ink.

---

### 🎮 Nhóm 2: Trò Chơi Trí Tuệ Rèn Luyện Não Bộ (E-ink Casual Games)

Màn hình E-ink có tốc độ phản hồi thích hợp nhất cho các tựa game tư duy theo lượt (Turn-based):

#### 1. 🔢 Plugin Sudoku Zen (Ma Trận 9x9 với 4 Cấp Độ)
- **Ý tưởng**: Trò chơi giải đố Sudoku với các mức Dễ, Trung Bình, Khó, Chuyên Gia.
- **Giải pháp kỹ thuật**:
  - Ma trận $9 \times 9$ vẽ bằng các ô lưới viền đậm nhạt rõ ràng.
  - Hỗ trợ chế độ "Ghi chú bút chì" (Pencil marks) cho các số dự đoán nhỏ trong ô.
  - Tự động lưu ván cờ dở dang vào `/sdcard/plugins/sudoku/savegame.dat`.

#### 2. ❌⭕ Plugin Cờ Caro / Gomoku (Đấu Với Máy AI Minimax)
- **Ý tưởng**: Bàn cờ Caro $15 \times 15$ đấu với thuật toán AI máy tính.
- **Giải pháp kỹ thuật**:
  - Sử dụng thuật toán tìm kiếm cây quyết định **Minimax với Alpha-Beta Pruning** với độ sâu tìm kiếm 3-4 nước cờ (chạy mất < 0.2s trong môi trường Lua 5.4 trên vi điều khiển ESP32-C3 160MHz).
  - Điều hướng con trỏ bàn cờ bằng 4 phím `UP`, `DOWN`, `LEFT`, `RIGHT` và đánh cờ bằng phím `CONFIRM`.

#### 3. ♟️ Plugin Câu Đố Cờ Vua Hàng Ngày (Chess Tactics & Puzzles)
- **Ý tưởng**: Mỗi ngày cung cấp 1 bài thế cờ vua "Chiếu hết sau 2 nước" (Mate-in-2) trích xuất từ cơ sở dữ liệu thế cờ Lichess.
- **Giải pháp kỹ thuật**:
  - Lưu trữ cơ sở dữ liệu dạng chuỗi ký hiệu FEN (Forsyth–Edwards Notation) siêu nhẹ trên thẻ SD (~500 bài thế chỉ chiếm 50KB).
  - Trình phân giải FEN vẽ bàn cờ $8 \times 8$ cùng các quân cờ đồ họa đơn sắc độ tương phản cao.

---

### 📖 Nhóm 3: Công Cụ Hỗ Trợ Đọc Sách Chuyên Sâu (Reader Power Tools)

#### 1. ⏱️ Plugin Pomodoro Reader
- **Ý tưởng**: Hỗ trợ người đọc duy trì sự tập trung theo phương pháp Pomodoro (25 phút đọc sách - 5 phút nghỉ ngơi).
- **Giải pháp kỹ thuật**: Đồng hồ đếm ngược hiển thị góc nhỏ hoặc toàn màn hình, kết thúc phiên sẽ chớp nhẹ màn hình vi xung để nhắc nhở người đọc thư giãn mắt.

#### 2. 📇 Plugin Anki-Lite E-ink Flashcards
- **Ý tưởng**: Học từ vựng tiếng Anh, công thức hoặc kiến thức ghi nhớ trực tiếp trên máy đọc sách qua thẻ ghi nhớ Flashcard.
- **Giải pháp kỹ thuật**:
  - Đọc các tệp `.csv` hoặc `.txt` dạng `Từ vựng | Giải nghĩa` từ thư mục `/Flashcards/`.
  - Áp dụng thuật toán lặp lại ngắt quãng (Spaced Repetition System - SRS) dạng Leitner Box để ưu tiên xuất hiện các từ chưa thuộc.

---

## 8. 🛠️ HƯỚNG DẪN TẠO PLUGIN ĐẦU TIÊN TRONG 5 PHÚT

Dưới đây là ví dụ từng bước tạo một ứng dụng **Đồng hồ đếm ngược & Xem Pin E-ink** hoàn chỉnh:

### Bước 1: Tạo thư mục plugin
Tạo thư mục trên thẻ SD: `/plugins/battery_clock/`

### Bước 2: Tạo tệp `manifest.json`
```json
{
  "id": "battery_clock",
  "name": "Dong Ho & Pin E-ink",
  "version": "1.0.0",
  "author": "Dev",
  "category": "HOME_APP",
  "entry": "main.lua",
  "priority": 5,
  "enabled": true
}
```

### Bước 3: Viết mã nguồn `main.lua`
```lua
local isRunning = true

function onEnter()
    print("Dong Ho & Pin san sang!")
end

function onRender()
    ZInk.Display.clear()
    
    -- Ve tieu de
    ZInk.Display.drawRect(20, 20, 488, 60, true)
    ZInk.Display.drawText(40, 40, "DONG HO & TRANG THAI PIN", 14)
    
    -- Doc thong so he thong
    local bat = ZInk.System.getBatteryPercent()
    local mv = ZInk.System.getBatteryVoltage()
    local uptime = ZInk.System.getUptime()
    local freeHeap = math.floor(ZInk.System.getFreeHeap() / 1024)
    
    -- Ve khung thong so
    ZInk.Display.drawRect(20, 100, 488, 300, false)
    ZInk.Display.drawText(40, 140, "Dung luong Pin: " .. tostring(bat) .. " %", 12)
    ZInk.Display.drawText(40, 190, "Dien ap Li-Po:  " .. tostring(mv) .. " mV", 12)
    ZInk.Display.drawText(40, 240, "Bo nho RAM:     " .. tostring(freeHeap) .. " KB Free", 12)
    ZInk.Display.drawText(40, 290, "Thoi gian chay: " .. tostring(uptime) .. " giay", 12)
    
    -- Ve thanh pin do hoa
    ZInk.Display.drawRect(40, 340, 448, 30, false)
    local fillW = math.floor((448 - 4) * (bat / 100))
    if fillW > 0 then
        ZInk.Display.drawRect(42, 342, fillW, 26, true)
    end
    
    -- Huong dan bam phim
    ZInk.Display.drawText(40, 440, "[CONFIRM]: Lam moi     [BACK]: Thoat", 12)
end

function onInput(button, action)
    if action == "RELEASE" then
        if button == "CONFIRM" then
            return true -- He thong se tu dong goi onRender() de ve lai
        elseif button == "BACK" then
            ZInk.UI.popView() -- Thoat ve man hinh Home
            return true
        end
    end
    return false
end

function onExit()
    print("Tam biet!")
end
```

### Bước 4: Trải nghiệm
Cắm thẻ SD vào máy đọc sách Xteink X3, khởi động thiết bị và chọn mục **"Dong Ho & Pin E-ink"** ngay trên màn hình chính!

---

## 9. 🚀 XUẤT BẢN & XÂY DỰNG CHỢ PLUGIN CỘNG ĐỒNG (COMMUNITY REPOSITORY)

Cộng đồng lập trình viên có thể chia sẻ plugin bằng cách:
1. Đóng gói thư mục plugin thành tệp `.zip` (chứa `manifest.json` và `main.lua`).
2. Gửi Pull Request vào kho lưu trữ chính thức: [https://github.com/magicxlll/Z-CrossInk](https://github.com/magicxlll/Z-CrossInk).
3. Ứng dụng **Z-Truyen trên điện thoại Android** trong các phiên bản kế tiếp sẽ tích hợp tính năng **"Cửa Hàng Plugin" (Plugin Store)**: Người dùng điện thoại chỉ cần nhấn `[Cài Đặt]` trên ứng dụng Z-Truyen, tệp plugin sẽ được tự động nạp không dây qua Wi-Fi / WebDAV vào thẻ nhớ của máy đọc sách trong 1 giây!
