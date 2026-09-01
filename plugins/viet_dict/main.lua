-- =======================================================================
-- Plugin Tu Dien Viet - Anh (Offline Quick Dictionary for Z-CrossInk)
-- Target Screen: Xteink X3 (528x792 E-ink Monochrome Display)
-- Standard: Z-Plugin Spec v1.0
-- =======================================================================

local VIEW_LIST = 1
local VIEW_DETAIL = 2
local currentView = VIEW_LIST
local selectedIndex = 1
local pageSize = 7
local currentPage = 1

-- Sample offline dictionary dataset (Vietnamese -> English)
local dictionaryData = {
    {
        word = "Ban Mai",
        phonetic = "[ba:n ma:i]",
        pos = "Danh tu (Noun)",
        meanings = {
            "Buoi sang som, khoang thoi gian mat troi moi moc.",
            "Bieu tuong cua su khoi dau tuoi moi va tran day hy vong."
        },
        en = "Early morning / Dawn / Sunrise",
        example = "Anh nang ban mai chieu qua khung cua so nho.",
        exampleEn = "The morning sunlight shined through the small window."
    },
    {
        word = "Bao Dung",
        phonetic = "[ba:w zu:ng]",
        pos = "Tinh tu (Adjective)",
        meanings = {
            "San sang tha thu, cam thong cho loi lam cua nguoi khac.",
            "Tam long rong luong, khong chap nhat nhung dieu nho nhat."
        },
        en = "Magnanimous / Tolerant / Forgiving / Benevolent",
        example = "Su bao dung giup han gan moi quan he do vo.",
        exampleEn = "Tolerance helps mend broken relationships."
    },
    {
        word = "Binh Minh",
        phonetic = "[bin min]",
        pos = "Danh tu (Noun)",
        meanings = {
            "Thoi diem rang dong khi mat troi bat dau nho len chan troi.",
            "Su bat dau ruc ro cua mot ngay moi hoac thoi ky moi."
        },
        en = "Sunrise / Daybreak / Dawn",
        example = "Don binh minh tren dinh nui la trai nghiem tuyet voi.",
        exampleEn = "Watching the sunrise on the mountain peak is amazing."
    },
    {
        word = "Binh Yen",
        phonetic = "[bin i:en]",
        pos = "Tinh tu (Adjective)",
        meanings = {
            "Trang thai tinh lang, yen a, khong co bien co hay song gio.",
            "Cam giac thanh than trong tam hon khi doc sach ben tach tra."
        },
        en = "Peaceful / Serene / Tranquil / Calm",
        example = "Doc sach tren may doc sach mang lai su binh yen.",
        exampleEn = "Reading on an e-reader brings profound serenity."
    },
    {
        word = "Co Gang",
        phonetic = "[ko: ga:ng]",
        pos = "Dong tu / Danh tu",
        meanings = {
            "Dung het suc luc va y chi de hoan thanh mot muc tieu kho khan.",
            "No luc khong ngung nghi truoc cac thu thach."
        },
        en = "Endeavor / Strive / Make effort / Exert",
        example = "Moi ngay co gang them mot chut se tao nen ki tich.",
        exampleEn = "A little daily effort creates extraordinary miracles."
    },
    {
        word = "Dung Cam",
        phonetic = "[zu:ng ka:m]",
        pos = "Tinh tu (Adjective)",
        meanings = {
            "Khong so hai truoc nguy hiem, gian kho va thu thach.",
            "Dam doi mat voi su that va bao ve le phai."
        },
        en = "Brave / Courageous / Valiant / Bold",
        example = "Nguoi chien si dung cam vuot qua hiem nguy.",
        exampleEn = "The brave soldier overcame every hazard."
    },
    {
        word = "Hanh Phuc",
        phonetic = "[ha:nh fu:k]",
        pos = "Danh tu / Tinh tu",
        meanings = {
            "Trang thai sung suong vi cam thay hoan toan dat duoc y nguyen.",
            "Niem vui gian di trong tung khoanh khac cuoc song."
        },
        en = "Happiness / Bliss / Felicity / Joyful",
        example = "Hanh phuc la duoc doc cuon sach minh yeu thich.",
        exampleEn = "Happiness is reading your favorite book."
    },
    {
        word = "Hy Vong",
        phonetic = "[hi: vo:ng]",
        pos = "Dong tu / Danh tu",
        meanings = {
            "Tin tuong va mong doi nhung dieu tot dep se den trong tuong lai.",
            "Ngon lua thap sang niem tin khi gap tro ngai."
        },
        en = "Hope / Aspire / Expectation / Wish",
        example = "Dung bao gio danh mat ngon lua hy vong trong tim.",
        exampleEn = "Never lose the spark of hope in your heart."
    },
    {
        word = "Kien Tri",
        phonetic = "[ki:en tri:]",
        pos = "Tinh tu / Danh tu",
        meanings = {
            "Ben bi tiep tuc muc tieu du gap nhieu tro ngai va that bai.",
            "Pham chat quy gia cua nguoi thanh cong."
        },
        en = "Perseverance / Persistence / Tenacity / Diligence",
        example = "Kien tri hoc tap giup mo ra canh cua tri thuc.",
        exampleEn = "Persistent studying unlocks the gateway to knowledge."
    },
    {
        word = "Muc Dien Tu",
        phonetic = "[mu:k di:en tu:]",
        pos = "Danh tu (Noun)",
        meanings = {
            "Cong nghe man hinh phan chieu anh sang tu nhien, khong phat quang.",
            "Bao ve mat, tiet kiem pin, hien thi sac net nhu trang giay in."
        },
        en = "E-ink / Electronic Paper / E-paper Display",
        example = "Man hinh muc dien tu doc ro ngay ca duoi anh nang mat troi.",
        exampleEn = "E-ink display remains crystal clear under direct sunlight."
    },
    {
        word = "Tri Thuc",
        phonetic = "[tri: thu:k]",
        pos = "Danh tu (Noun)",
        meanings = {
            "Tong the hieu biet, kinh nghiem va kien thuc ma con nguoi tich luy.",
            "Tai san quy gia nhat cua nhan loai."
        },
        en = "Knowledge / Erudition / Intellect / Wisdom",
        example = "Sach la kho tang vo tan cua tri thuc nhan loai.",
        exampleEn = "Books are the infinite treasure trove of human knowledge."
    },
    {
        word = "Tuong Lai",
        phonetic = "[tu:ong la:i]",
        pos = "Danh tu (Noun)",
        meanings = {
            "Khoang thoi gian tiep noi sau hien tai.",
            "Nhung gi se xay ra va co the duoc kien tao boi hanh dong hom nay."
        },
        en = "Future / Destiny / Prospective",
        example = "Hanh dong hom nay quyet dinh tuong lai ngay mai.",
        exampleEn = "Today's action shapes tomorrow's future."
    },
    {
        word = "Yeu Thuong",
        phonetic = "[i:ew thu:ong]",
        pos = "Dong tu / Danh tu",
        meanings = {
            "Tinh cam gan bo, tha thiet va quan tam sau sac den nguoi khac.",
            "Su san se, chia ngot se bui trong cong dong."
        },
        en = "Love / Affection / Cherish / Warmth",
        example = "Lan toa yeu thuong den moi nguoi xung quanh.",
        exampleEn = "Spread love and warmth to everyone around."
    },
    {
        word = "Z-CrossInk",
        phonetic = "[zet kro:s ink]",
        pos = "He dieu hanh / Cong nghe",
        meanings = {
            "He dieu hanh doc sach ma nguon mo toi uu chuyen biet cho thiet bi E-ink.",
            "Ho tro Plugin Lua mo rong, KOSync va hien thi tiep van cuc nhanh."
        },
        en = "Z-CrossInk E-ink OS / Dynamic Plugin Ecosystem",
        example = "Z-CrossInk giup thiet bi E-ink tro nen manh me va linh hoat.",
        exampleEn = "Z-CrossInk empowers E-ink hardware with unparalleled agility."
    }
}

function onInit()
    print("[VietDict] Plugin initialized successfully")
end

function onEnter()
    currentView = VIEW_LIST
    selectedIndex = 1
    currentPage = 1
    print("[VietDict] Entered Vietnamese-English dictionary")
end

local function drawListView(w, h)
    -- 1. Header Box
    ZInk.Display.drawRect(20, 20, w - 40, 56, false)
    ZInk.Display.drawText(36, 56, "TU DIEN VIET - ANH OFFLINE", "BOLD", 16)
    ZInk.Display.drawText(w - 180, 56, "E-INK X3", "REGULAR", 12)
    ZInk.Display.drawLine(20, 86, w - 40, 86)

    -- 2. Subheader & Stats
    local totalWords = #dictionaryData
    local totalPages = math.ceil(totalWords / pageSize)
    currentPage = math.ceil(selectedIndex / pageSize)

    local subY = 110
    ZInk.Display.drawText(26, subY, "Tra cuu nhanh (" .. tostring(totalWords) .. " tu)  •  Trang " .. tostring(currentPage) .. "/" .. tostring(totalPages), "REGULAR", 12)
    ZInk.Display.drawLine(20, subY + 12, w - 40, subY + 12)

    -- 3. Render Page Items
    local startIdx = (currentPage - 1) * pageSize + 1
    local endIdx = math.min(startIdx + pageSize - 1, totalWords)
    local startY = 145
    local rowHeight = 75

    for i = startIdx, endIdx do
        local slot = i - startIdx
        local y = startY + slot * rowHeight
        local item = dictionaryData[i]
        local isSelected = (i == selectedIndex)

        if isSelected then
            -- Inverted selection container
            ZInk.Display.drawRect(22, y, w - 44, 65, true)
            ZInk.Display.drawText(40, y + 26, tostring(i) .. ". " .. item.word, "BOLD", 14)
            ZInk.Display.drawText(40, y + 50, "-> " .. item.en, "REGULAR", 12)
            ZInk.Display.drawText(w - 150, y + 26, item.pos, "REGULAR", 10)
        else
            ZInk.Display.drawRect(22, y, w - 44, 65, false)
            ZInk.Display.drawText(40, y + 26, tostring(i) .. ". " .. item.word, "BOLD", 14)
            ZInk.Display.drawText(40, y + 50, "-> " .. item.en, "REGULAR", 12)
            ZInk.Display.drawText(w - 150, y + 26, item.pos, "REGULAR", 10)
        end
    end

    -- 4. Footer Guide
    local footY = h - 60
    ZInk.Display.drawLine(20, footY, w - 40, footY)
    ZInk.Display.drawText(30, footY + 36, "[Len/Xuong: Chon tu | Confirm: Xem nghia | Back: Thoat]", "REGULAR", 10)
end

local function drawDetailView(w, h)
    local item = dictionaryData[selectedIndex]
    if not item then return end

    -- 1. Header Box
    ZInk.Display.drawRect(20, 20, w - 40, 56, false)
    ZInk.Display.drawText(36, 56, "CHI TIET TU VUNG", "BOLD", 16)
    ZInk.Display.drawText(w - 150, 56, "[" .. tostring(selectedIndex) .. "/" .. tostring(#dictionaryData) .. "]", "REGULAR", 12)
    ZInk.Display.drawLine(20, 86, w - 40, 86)

    -- 2. Word Card Banner
    local cardY = 105
    ZInk.Display.drawRect(24, cardY, w - 48, 70, false)
    ZInk.Display.drawText(40, cardY + 34, item.word, "BOLD", 20)
    ZInk.Display.drawText(40, cardY + 56, item.phonetic .. "  •  " .. item.pos, "REGULAR", 12)

    -- 3. English Meaning Box
    local enY = cardY + 85
    ZInk.Display.drawRect(24, enY, w - 48, 55, true)
    ZInk.Display.drawText(38, enY + 24, "ENGLISH DEFINITION:", "BOLD", 10)
    ZInk.Display.drawText(38, enY + 44, item.en, "BOLD", 13)

    -- 4. Vietnamese Meanings
    local vnY = enY + 70
    ZInk.Display.drawText(28, vnY, "Giai nghia tieng Viet:", "BOLD", 13)
    ZInk.Display.drawLine(28, vnY + 6, 200, vnY + 6)

    local curY = vnY + 30
    for idx, def in ipairs(item.meanings) do
        ZInk.Display.drawText(34, curY, tostring(idx) .. ". " .. def, "REGULAR", 12)
        curY = curY + 28
    end

    -- 5. Example Box
    local exY = curY + 20
    ZInk.Display.drawRect(24, exY, w - 48, 110, false)
    ZInk.Display.drawText(38, exY + 26, "Vi du minh hoa (Examples):", "BOLD", 12)
    ZInk.Display.drawText(38, exY + 54, "• VN: \"" .. item.example .. "\"", "REGULAR", 11)
    ZInk.Display.drawText(38, exY + 84, "• EN: \"" .. item.exampleEn .. "\"", "REGULAR", 11)

    -- 6. Navigation Footer
    local footY = h - 60
    ZInk.Display.drawLine(20, footY, w - 40, footY)
    ZInk.Display.drawText(30, footY + 36, "[Trai/Phai: Tu truoc/sau | Confirm/Back: Tro lai danh sach]", "REGULAR", 10)
end

function onRender()
    local w = ZInk.Display.getWidth()
    local h = ZInk.Display.getHeight()

    ZInk.Display.clear()

    if currentView == VIEW_LIST then
        drawListView(w, h)
    else
        drawDetailView(w, h)
    end
end

function onInput(key, eventType)
    if eventType ~= "RELEASE" then
        return false
    end

    local totalWords = #dictionaryData

    if currentView == VIEW_LIST then
        if key == "LEFT" or key == "UP" or key == "PAGE_PREV" or key == "VOL_DOWN" then
            selectedIndex = selectedIndex - 1
            if selectedIndex < 1 then selectedIndex = totalWords end
            return true
        elseif key == "RIGHT" or key == "DOWN" or key == "PAGE_NEXT" or key == "VOL_UP" then
            selectedIndex = selectedIndex + 1
            if selectedIndex > totalWords then selectedIndex = 1 end
            return true
        elseif key == "CONFIRM" then
            currentView = VIEW_DETAIL
            return true
        elseif key == "BACK" then
            ZInk.UI.popView()
            return true
        end
    elseif currentView == VIEW_DETAIL then
        if key == "LEFT" or key == "UP" or key == "PAGE_PREV" or key == "VOL_DOWN" then
            selectedIndex = selectedIndex - 1
            if selectedIndex < 1 then selectedIndex = totalWords end
            return true
        elseif key == "RIGHT" or key == "DOWN" or key == "PAGE_NEXT" or key == "VOL_UP" then
            selectedIndex = selectedIndex + 1
            if selectedIndex > totalWords then selectedIndex = 1 end
            return true
        elseif key == "CONFIRM" or key == "BACK" then
            currentView = VIEW_LIST
            return true
        end
    end

    return false
end

function onExit()
    print("[VietDict] Exited dictionary plugin")
end
