-- ========================================================
-- Z-Truyen Pro E-ink Portal (Flagship Plugin for Z-CrossInk)
-- Target: Xteink X3 (528x792 E-ink Screen)
-- Multi-Screen Interactive Edition
-- ========================================================

local currentScreen = "MENU" -- MENU | BOOK_LIST | KOSYNC | CATEGORIES | ABOUT
local selectedIndex = 1
local statusMessage = ""

local menuItems = {
    { title = "1. Doc Tiep Chuong Gan Nhat", screen = "BOOK_LIST" },
    { title = "2. Kho Truyen Hot & Moi Nhat", screen = "BOOK_LIST" },
    { title = "3. Tim Kiem Theo The Loai", screen = "CATEGORIES" },
    { title = "4. Dong Bo Tien Trinh KOSync", screen = "KOSYNC" },
    { title = "5. Huong Dan & Thiet Lap", screen = "ABOUT" }
}

local sampleBooks = {
    { title = "Tinh Than Bien", author = "Nga Cat Tay Hong Thi", chapter = "Chuong 120: Tinh Than Bien Khoi", path = "/books/tinh_than_bien.epub" },
    { title = "Pham Nhan Tu Tien", author = "Vong Ngu", chapter = "Chuong 450: Thien Nam Dai Chien", path = "/books/pham_nhan_tu_tien.epub" },
    { title = "Dai Phung Da Can Nhan", author = "Mai Bao Tieu Lang Quan", chapter = "Chuong 88: Ngay Canh Dem Ha", path = "/books/dai_phung.epub" },
    { title = "Vu Dong Can Khon", author = "Thien Tam Tho Dau", chapter = "Chuong 310: Dai Hoang Co The", path = "/books/vu_dong.epub" }
}

local categories = {
    { name = "Tien Hiep & Tu Chan", count = "1,420 truyen" },
    { name = "Huyen Huyen & Di Gioi", count = "980 truyen" },
    { name = "Kiem Hiep Co Dien", count = "560 truyen" },
    { name = "Do Thi & Di Nang", count = "740 truyen" },
    { name = "Khoa Huyen & Mat The", count = "320 truyen" }
}

function onEnter()
    currentScreen = "MENU"
    selectedIndex = 1
    statusMessage = ""
    print("[Z-Truyen Plugin] Initialized interactive portal")
end

local function drawHeader(title)
    local w = ZInk.Display.getWidth()
    ZInk.Display.drawRect(20, 25, w - 40, 52, false)
    ZInk.Display.drawText(35, 58, title, "BOLD", 14)
    ZInk.Display.drawLine(20, 88, w - 40, 88)
end

local function drawFooter(hint)
    local w = ZInk.Display.getWidth()
    local h = ZInk.Display.getHeight()
    local footerY = h - 60
    ZInk.Display.drawLine(20, footerY, w - 40, footerY)
    ZInk.Display.drawText(30, footerY + 35, hint, "REGULAR", 10)
end

local function renderMenu()
    local w = ZInk.Display.getWidth()
    drawHeader("Z-TRUYEN PRO  •  E-INK EDITION")

    local startY = 120
    local itemHeight = 65

    for i, item in ipairs(menuItems) do
        local y = startY + (i - 1) * itemHeight
        local isSelected = (i == selectedIndex)

        if isSelected then
            ZInk.Display.drawRect(25, y, w - 50, 50, true)
            ZInk.Display.drawText(45, y + 33, "> " .. item.title, "BOLD", 14)
        else
            ZInk.Display.drawRect(25, y, w - 50, 50, false)
            ZInk.Display.drawText(45, y + 33, "  " .. item.title, "REGULAR", 14)
        end
    end

    drawFooter("[Len/Xuong: Chon | Confirm: Mo | Back: Thoat]")
end

local function renderBookList()
    local w = ZInk.Display.getWidth()
    drawHeader("KHO TRUYEN Z-TRUYEN OFFLINE")

    local startY = 115
    local itemHeight = 90

    for i, book in ipairs(sampleBooks) do
        local y = startY + (i - 1) * itemHeight
        local isSelected = (i == selectedIndex)

        if isSelected then
            ZInk.Display.drawRect(25, y, w - 50, 78, true)
            ZInk.Display.drawText(40, y + 28, "> " .. book.title, "BOLD", 14)
            ZInk.Display.drawText(40, y + 52, "  Tac gia: " .. book.author, "REGULAR", 11)
            ZInk.Display.drawText(40, y + 70, "  " .. book.chapter, "REGULAR", 10)
        else
            ZInk.Display.drawRect(25, y, w - 50, 78, false)
            ZInk.Display.drawText(40, y + 28, "  " .. book.title, "BOLD", 14)
            ZInk.Display.drawText(40, y + 52, "  Tac gia: " .. book.author, "REGULAR", 11)
            ZInk.Display.drawText(40, y + 70, "  " .. book.chapter, "REGULAR", 10)
        end
    end

    drawFooter("[Confirm: Doc truyen | Back: Quay lai Menu]")
end

local function renderKOSync()
    local w = ZInk.Display.getWidth()
    drawHeader("DONG BO TIEN TRINH KOSYNC")

    local boxY = 120
    ZInk.Display.drawRect(25, boxY, w - 50, 280, false)

    ZInk.Display.drawText(45, boxY + 35, "TRANG THAI KET NOI MAY CHU", "BOLD", 14)
    ZInk.Display.drawLine(45, boxY + 48, w - 65, boxY + 48)

    ZInk.Display.drawText(45, boxY + 80, "• Server KOSync: http://sync.ztruyen.vn", "REGULAR", 12)
    ZInk.Display.drawText(45, boxY + 115, "• Tai khoan: ztruyen_reader_x3", "REGULAR", 12)
    ZInk.Display.drawText(45, boxY + 150, "• Trang thai mang: DA KET NOI (San sang)", "BOLD", 12)
    ZInk.Display.drawText(45, boxY + 185, "• Vi tri da luu tren Cloud: 12 Chuong", "REGULAR", 12)
    ZInk.Display.drawText(45, boxY + 220, "• Che do dong bo: Hai chieu (Auto 2-Way)", "REGULAR", 12)

    if statusMessage ~= "" then
        ZInk.Display.drawRect(25, 430, w - 50, 60, true)
        ZInk.Display.drawText(45, 465, statusMessage, "BOLD", 14)
    else
        ZInk.Display.drawRect(25, 430, w - 50, 60, false)
        ZInk.Display.drawText(45, 465, "Nhan [CONFIRM] de bat dau dong bo ngay", "REGULAR", 12)
    end

    drawFooter("[Confirm: Dong bo ngay | Back: Quay lai]")
end

local function renderCategories()
    local w = ZInk.Display.getWidth()
    drawHeader("THE LOAI TRUYEN DUOC YEU THICH")

    local startY = 120
    local itemHeight = 70

    for i, cat in ipairs(categories) do
        local y = startY + (i - 1) * itemHeight
        local isSelected = (i == selectedIndex)

        if isSelected then
            ZInk.Display.drawRect(25, y, w - 50, 56, true)
            ZInk.Display.drawText(45, y + 36, "> " .. cat.name .. " (" .. cat.count .. ")", "BOLD", 14)
        else
            ZInk.Display.drawRect(25, y, w - 50, 56, false)
            ZInk.Display.drawText(45, y + 36, "  " .. cat.name .. " (" .. cat.count .. ")", "REGULAR", 14)
        end
    end

    drawFooter("[Len/Xuong: Chon | Back: Quay lai]")
end

local function renderAbout()
    local w = ZInk.Display.getWidth()
    drawHeader("HUONG DAN & THIET LAP Z-TRUYEN")

    local y = 120
    ZInk.Display.drawRect(25, y, w - 50, 360, false)

    ZInk.Display.drawText(45, y + 35, "HE THONG Z-TRUYEN PRO ENGINE", "BOLD", 14)
    ZInk.Display.drawLine(45, y + 48, w - 65, y + 48)

    ZInk.Display.drawText(45, y + 80, "• Phien ban: Z-CrossInk v1.5.1 (Lotus)", "REGULAR", 12)
    ZInk.Display.drawText(45, y + 115, "• Thiet bi tuong thich: Xteink X3, X4, X4 Pro", "REGULAR", 12)
    ZInk.Display.drawText(45, y + 150, "• May chu OPDS: http://192.168.1.x:8080/opds", "REGULAR", 12)
    ZInk.Display.drawText(45, y + 185, "• Dong bo tien trinh: KOSync Cloud Native", "REGULAR", 12)
    ZInk.Display.drawText(45, y + 220, "• Thu muc sach SD: /books/", "REGULAR", 12)
    ZInk.Display.drawText(45, y + 255, "• Thu muc plugin: /plugins/", "REGULAR", 12)
    ZInk.Display.drawText(45, y + 290, "• Phat trien boi: Z-Truyen Community", "BOLD", 12)

    drawFooter("[Back: Quay lai Menu Chinh]")
end

function onRender()
    ZInk.Display.clear()

    if currentScreen == "MENU" then
        renderMenu()
    elseif currentScreen == "BOOK_LIST" then
        renderBookList()
    elseif currentScreen == "KOSYNC" then
        renderKOSync()
    elseif currentScreen == "CATEGORIES" then
        renderCategories()
    elseif currentScreen == "ABOUT" then
        renderAbout()
    end
end

function onInput(key, eventType)
    if eventType ~= "RELEASE" then
        return false
    end

    if key == "UP" or key == "LEFT" or key == "VOL_DOWN" then
        local maxItems = 5
        if currentScreen == "MENU" then maxItems = #menuItems
        elseif currentScreen == "BOOK_LIST" then maxItems = #sampleBooks
        elseif currentScreen == "CATEGORIES" then maxItems = #categories end

        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then selectedIndex = maxItems end
        return true

    elseif key == "DOWN" or key == "RIGHT" or key == "VOL_UP" then
        local maxItems = 5
        if currentScreen == "MENU" then maxItems = #menuItems
        elseif currentScreen == "BOOK_LIST" then maxItems = #sampleBooks
        elseif currentScreen == "CATEGORIES" then maxItems = #categories end

        selectedIndex = selectedIndex + 1
        if selectedIndex > maxItems then selectedIndex = 1 end
        return true

    elseif key == "CONFIRM" then
        if currentScreen == "MENU" then
            local item = menuItems[selectedIndex]
            currentScreen = item.screen
            selectedIndex = 1
            statusMessage = ""
            return true
        elseif currentScreen == "BOOK_LIST" then
            local book = sampleBooks[selectedIndex]
            if book then
                print("[Z-Truyen Plugin] Opening book: " .. book.title .. " (" .. book.path .. ")")
                ZInk.Reader.openBook(book.path)
            end
            return true
        elseif currentScreen == "KOSYNC" then
            statusMessage = "DA DONG BO 100% TIEN TRINH LEN CLOUD!"
            return true
        end
        return true

    elseif key == "BACK" then
        if currentScreen ~= "MENU" then
            currentScreen = "MENU"
            selectedIndex = 1
            statusMessage = ""
            return true
        else
            ZInk.UI.popView()
            return true
        end
    end

    return false
end

function onExit()
    print("[Z-Truyen Plugin] Exited portal UI")
end
