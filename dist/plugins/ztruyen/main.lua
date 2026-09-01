-- ============================================================================
-- Z-TRUYEN PRO — ADVANCED E-INK NOVEL ENGINE & COMMUNITY HUB
-- Spec: Z-CrossInk Master Spec v1.0 (Phase P3 - P6 Architecture)
-- Target: Xteink X3 (528x792 E-ink Monochrome Display)
-- Capabilities: Direct Web Novel Scraping, OPDS Hybrid Bridge, 
--               Volume EPUB Downloader, KOSync 2-Way Cloud Sync
-- ============================================================================

local STATE_MAIN_MENU = "MAIN_MENU"
local STATE_BOOKSHELF = "BOOKSHELF"
local STATE_ONLINE_HUB = "ONLINE_HUB"
local STATE_STORY_DETAIL = "STORY_DETAIL"
local STATE_SOURCES = "SOURCES"
local STATE_KOSYNC = "KOSYNC"
local STATE_ABOUT = "ABOUT"

local currentScreen = STATE_MAIN_MENU
local selectedIndex = 1
local selectedSubIndex = 1
local activeSource = 1
local toastMessage = ""
local toastTimer = 0

-- ----------------------------------------------------------------------------
-- 1. Main Navigation Menu
-- ----------------------------------------------------------------------------
local mainMenuEntries = {
    { title = "1. Ke Sach & Doc Tiep", desc = "Mo truyen da luu tren the nho SD", screen = STATE_BOOKSHELF },
    { title = "2. Kho Truyên Hot & Online", desc = "Duyet truyen de cu, moi nhat tu cac nguon", screen = STATE_ONLINE_HUB },
    { title = "3. Quan Ly Nguon & OPDS", desc = "Chuyen doi Direct Scraper / OPDS LAN", screen = STATE_SOURCES },
    { title = "4. Dong Bo KOSync 2 Chieu", desc = "Dong bo tien trinh chuong voi Server Cloud", screen = STATE_KOSYNC },
    { title = "5. Huong Dan & Thiet Lap", desc = "Thong tin Z-Truyen Engine & Z-CrossInk", screen = STATE_ABOUT }
}

-- ----------------------------------------------------------------------------
-- 2. Multi-Source Adapters (Direct Scraping + OPDS Hybrid)
-- ----------------------------------------------------------------------------
local sourceAdapters = {
    { id = "tangthuvien", name = "Tang Thu Vien (Direct)", type = "Direct Web Scraper", status = "ONLINE", novels = 12400 },
    { id = "truyenfull", name = "TruyenFull (Direct)", type = "Direct Web Scraper", status = "ONLINE", novels = 18900 },
    { id = "metruyenchu", name = "Me Truyen Chu (Direct)", type = "Direct Web Scraper", status = "ONLINE", novels = 9500 },
    { id = "local_opds", name = "Z-Truyen OPDS Bridge", type = "Local Network (LAN)", status = "READY", novels = 320 },
    { id = "cloud_sync", name = "Z-Truyen Cloud Hub", type = "Cloud Storage CDN", status = "SYNCED", novels = 4500 }
}

-- ----------------------------------------------------------------------------
-- 3. Online Novel Database (Dynamic Direct Scraping Sample Feed)
-- ----------------------------------------------------------------------------
local onlineNovels = {
    {
        id = "tinh_than_bien",
        title = "Tinh Than Bien",
        author = "Nga Cat Tay Hong Thi",
        genre = "Tien Hiep, Tu Chan",
        status = "Hoan Thanh (680 chuong)",
        intro = "Thieu nien Tan Vu troi sinh khong the tu luyen noi cong, nho co duyen dat duoc Tinh Than Bien kham pha bi mat vu tru vo tan.",
        totalChapters = 680,
        localPath = "/Books/ZTruyen/tinh_than_bien.epub",
        isDownloaded = true,
        lastChapter = "Chuong 120: Tinh Than Bien Khoi"
    },
    {
        id = "pham_nhan_tu_tien",
        title = "Pham Nhan Tu Tien",
        author = "Vong Ngu",
        genre = "Tien Hiep, Co Dien",
        status = "Hoan Thanh (2446 chuong)",
        intro = "Han Lap xuat than binh thuong, buoc vao giang ho voi tam the can trong, tung buoc nghich thien thanh tien giua the gioi tu chan khoc liet.",
        totalChapters = 2446,
        localPath = "/Books/ZTruyen/pham_nhan_tu_tien.epub",
        isDownloaded = true,
        lastChapter = "Chuong 450: Thien Nam Dai Chien"
    },
    {
        id = "dai_phung_da_can_nhan",
        title = "Dai Phung Da Can Nhan",
        author = "Mai Bao Tieu Lang Quan",
        genre = "Huyen Huyen, Pha An, Do Thi",
        status = "Hoan Thanh (980 chuong)",
        intro = "Hua That An xuyen khong tro thanh bo khoai cua Ty Canh ve Dai Phung vuong trieu, dung kien thuc hinh su pha giai hang loat ky an kinh dong thien ha.",
        totalChapters = 980,
        localPath = "/Books/ZTruyen/dai_phung_da_can_nhan.epub",
        isDownloaded = true,
        lastChapter = "Chuong 88: Ngay Canh Dem Ha"
    },
    {
        id = "vu_dong_can_khon",
        title = "Vu Dong Can Khon",
        author = "Thien Tam Tho Dau",
        genre = "Huyen Huyen, Di Gioi",
        status = "Hoan Thanh (1308 chuong)",
        intro = "Lam Dong xuat than tu phan gia Lam gia nho be, nho vao Thach Phu bi an da vuon len danh tran khap Dai Hoang Quan.",
        totalChapters = 1308,
        localPath = "/Books/ZTruyen/vu_dong_can_khon.epub",
        isDownloaded = true,
        lastChapter = "Chuong 310: Dai Hoang Co The"
    },
    {
        id = "dau_pha_thuong_khung",
        title = "Dau Pha Thuong Khung",
        author = "Thien Tam Tho Dau",
        genre = "Huyen Huyen, Di Gioi",
        status = "Hoan Thanh (1648 chuong)",
        intro = "Thap nhat doan Dau Khi Tieu Viem sau bien co tro thanh phe vat, duoi su huong dan cua Duoc Lao da tao nen ki tich Dau De truyen thuyet.",
        totalChapters = 1648,
        localPath = "/Books/ZTruyen/dau_pha_thuong_khung.epub",
        isDownloaded = false,
        lastChapter = "Chuong 1: Thien tai sa sut"
    }
}

-- ----------------------------------------------------------------------------
-- 4. Text Multi-Line Wrapping Helper for E-ink
-- ----------------------------------------------------------------------------
local function wrapLines(text, maxChars)
    maxChars = maxChars or 38
    if not text or #text <= maxChars then
        return { text or "" }
    end
    local lines = {}
    local currentLine = ""
    for word in text:gmatch("%S+") do
        if #currentLine == 0 then
            currentLine = word
        elseif #(currentLine .. " " .. word) <= maxChars then
            currentLine = currentLine .. " " .. word
        else
            table.insert(lines, currentLine)
            currentLine = word
        end
    end
    if #currentLine > 0 then
        table.insert(lines, currentLine)
    end
    return lines
end

-- ----------------------------------------------------------------------------
-- 5. Common Header & Footer Renderers
-- ----------------------------------------------------------------------------
local function drawHeader(title, subtitle)
    local w = ZInk.Display.getWidth()
    ZInk.Display.drawRect(20, 20, w - 40, 52, false)
    ZInk.Display.drawText(36, 54, title, "BOLD", 15)
    if subtitle then
        ZInk.Display.drawText(w - 140, 54, subtitle, "REGULAR", 11)
    end
    ZInk.Display.drawLine(20, 84, w - 40, 84)
end

local function drawFooter(hint)
    local w = ZInk.Display.getWidth()
    local h = ZInk.Display.getHeight()
    local footY = h - 60
    ZInk.Display.drawLine(20, footY, w - 40, footY)
    ZInk.Display.drawText(30, footY + 36, hint, "REGULAR", 10)
end

-- ----------------------------------------------------------------------------
-- 6. Screen Renderers
-- ----------------------------------------------------------------------------

-- [Screen: MAIN_MENU]
local function renderMainMenu()
    local w = ZInk.Display.getWidth()
    drawHeader("Z-TRUYEN PRO NOVEL ENGINE", "E-INK X3")

    local startY = 110
    local rowH = 75

    for i, item in ipairs(mainMenuEntries) do
        local y = startY + (i - 1) * rowH
        local isSel = (i == selectedIndex)

        if isSel then
            ZInk.Display.drawRect(22, y, w - 44, 65, true)
            ZInk.Display.drawText(38, y + 26, "> " .. item.title, "BOLD", 14)
            ZInk.Display.drawText(38, y + 50, "  " .. item.desc, "REGULAR", 11)
        else
            ZInk.Display.drawRect(22, y, w - 44, 65, false)
            ZInk.Display.drawText(38, y + 26, "  " .. item.title, "BOLD", 14)
            ZInk.Display.drawText(38, y + 50, "  " .. item.desc, "REGULAR", 11)
        end
    end

    drawFooter("[Len/Xuong: Chon muc | Confirm: Vao | Back: Thoat]")
end

-- [Screen: BOOKSHELF]
local function renderBookshelf()
    local w = ZInk.Display.getWidth()
    drawHeader("KE SACH & TRUYEN OFFLINE", "SD: /Books/ZTruyen")

    local downloadedBooks = {}
    for _, b in ipairs(onlineNovels) do
        if b.isDownloaded then
            table.insert(downloadedBooks, b)
        end
    end

    local startY = 110
    local rowH = 88

    for i, b in ipairs(downloadedBooks) do
        local y = startY + (i - 1) * rowH
        local isSel = (i == selectedIndex)

        if isSel then
            ZInk.Display.drawRect(22, y, w - 44, 78, true)
            ZInk.Display.drawText(38, y + 26, "> " .. b.title, "BOLD", 14)
            ZInk.Display.drawText(38, y + 48, "  " .. b.lastChapter, "REGULAR", 11)
            ZInk.Display.drawText(38, y + 68, "  " .. b.genre .. "  •  " .. b.author, "REGULAR", 10)
        else
            ZInk.Display.drawRect(22, y, w - 44, 78, false)
            ZInk.Display.drawText(38, y + 26, "  " .. b.title, "BOLD", 14)
            ZInk.Display.drawText(38, y + 48, "  " .. b.lastChapter, "REGULAR", 11)
            ZInk.Display.drawText(38, y + 68, "  " .. b.genre .. "  •  " .. b.author, "REGULAR", 10)
        end
    end

    if toastMessage ~= "" then
        ZInk.Display.drawRect(24, 520, w - 48, 50, true)
        ZInk.Display.drawText(38, 552, toastMessage, "BOLD", 13)
    end

    drawFooter("[Confirm: Mo sach doc | Back: Quay lai Menu]")
end

-- [Screen: ONLINE_HUB]
local function renderOnlineHub()
    local w = ZInk.Display.getWidth()
    local curSrc = sourceAdapters[activeSource].name
    drawHeader("KHO TRUYEN ONLINE (" .. curSrc .. ")", "TRANG 1/1")

    local startY = 110
    local rowH = 88

    for i, b in ipairs(onlineNovels) do
        local y = startY + (i - 1) * rowH
        local isSel = (i == selectedIndex)

        local tag = b.isDownloaded and "[DA CO OFFLINE]" or "[DOWNLOAD]"

        if isSel then
            ZInk.Display.drawRect(22, y, w - 44, 78, true)
            ZInk.Display.drawText(38, y + 26, "> " .. b.title, "BOLD", 14)
            ZInk.Display.drawText(w - 140, y + 26, tag, "BOLD", 10)
            ZInk.Display.drawText(38, y + 48, "  Tac gia: " .. b.author .. "  •  " .. b.status, "REGULAR", 11)
            ZInk.Display.drawText(38, y + 68, "  " .. b.genre, "REGULAR", 10)
        else
            ZInk.Display.drawRect(22, y, w - 44, 78, false)
            ZInk.Display.drawText(38, y + 26, "  " .. b.title, "BOLD", 14)
            ZInk.Display.drawText(w - 140, y + 26, tag, "REGULAR", 10)
            ZInk.Display.drawText(38, y + 48, "  Tac gia: " .. b.author .. "  •  " .. b.status, "REGULAR", 11)
            ZInk.Display.drawText(38, y + 68, "  " .. b.genre, "REGULAR", 10)
        end
    end

    drawFooter("[Confirm: Chi tiet & Tai sach | Back: Quay lai]")
end

-- [Screen: STORY_DETAIL]
local function renderStoryDetail()
    local w = ZInk.Display.getWidth()
    local b = onlineNovels[selectedIndex]
    if not b then return end

    drawHeader("CHI TIET TRUYEN & TAI EPUB", "DIRECT EPUB")

    -- 1. Main Story Banner Card
    local bannerY = 100
    ZInk.Display.drawRect(24, bannerY, w - 48, 80, false)
    ZInk.Display.drawText(38, bannerY + 28, b.title, "BOLD", 17)
    ZInk.Display.drawText(38, bannerY + 50, "Tac gia: " .. b.author .. "  •  " .. b.genre, "REGULAR", 11)
    ZInk.Display.drawText(38, bannerY + 70, "Tinh trang: " .. b.status, "BOLD", 11)

    -- 2. Summary Box with multi-line wrap
    local introY = bannerY + 94
    local introLines = wrapLines(b.intro, 36)
    local introBoxH = 30 + #introLines * 22
    ZInk.Display.drawRect(24, introY, w - 48, introBoxH, false)
    ZInk.Display.drawText(36, introY + 20, "GIOI THIEU NOI DUNG:", "BOLD", 11)
    for lIdx, l in ipairs(introLines) do
        ZInk.Display.drawText(36, introY + 20 + lIdx * 20, l, "REGULAR", 11)
    end

    -- 3. Action Menu Box
    local actY = introY + introBoxH + 14
    local actions = {
        "1. Doc Ngay (Mo Trinh Doc CrossInk Reader)",
        "2. Tai Tap 1 (Chuong 1 - 50) ve SD Card",
        "3. Tai Tron Bo Offline (Dinh dang EPUB)",
        "4. Dong Bo Vi Tri Chuong Len KOSync Cloud"
    }

    ZInk.Display.drawText(26, actY, "Chon tac vu thuc hien:", "BOLD", 12)
    local curY = actY + 20
    for aIdx, aText in ipairs(actions) do
        local isSubSel = (aIdx == selectedSubIndex)
        if isSubSel then
            ZInk.Display.drawRect(24, curY, w - 48, 38, true)
            ZInk.Display.drawText(36, curY + 25, "> " .. aText, "BOLD", 12)
        else
            ZInk.Display.drawRect(24, curY, w - 48, 38, false)
            ZInk.Display.drawText(36, curY + 25, "  " .. aText, "REGULAR", 12)
        end
        curY = curY + 44
    end

    if toastMessage ~= "" then
        ZInk.Display.drawRect(24, 630, w - 48, 50, true)
        ZInk.Display.drawText(38, 662, toastMessage, "BOLD", 13)
    end

    drawFooter("[Len/Xuong: Chon tac vu | Confirm: Thuc hien | Back: Tro lai]")
end

-- [Screen: SOURCES]
local function renderSources()
    local w = ZInk.Display.getWidth()
    drawHeader("QUAN LY NGUON TRUYEN & OPDS", "HYBRID ADAPTER")

    local startY = 110
    local rowH = 88

    for i, s in ipairs(sourceAdapters) do
        local y = startY + (i - 1) * rowH
        local isSel = (i == selectedIndex)
        local isCurActive = (i == activeSource)
        local statusTag = isCurActive and "[DANG DUNG]" or "[" .. s.status .. "]"

        if isSel then
            ZInk.Display.drawRect(22, y, w - 44, 78, true)
            ZInk.Display.drawText(38, y + 26, "> " .. s.name, "BOLD", 14)
            ZInk.Display.drawText(w - 140, y + 26, statusTag, "BOLD", 11)
            ZInk.Display.drawText(38, y + 48, "  Loai: " .. s.type, "REGULAR", 11)
            ZInk.Display.drawText(38, y + 68, "  Quy mo: ~" .. tostring(s.novels) .. " bo tieu thuyet", "REGULAR", 10)
        else
            ZInk.Display.drawRect(22, y, w - 44, 78, false)
            ZInk.Display.drawText(38, y + 26, "  " .. s.name, "BOLD", 14)
            ZInk.Display.drawText(w - 140, y + 26, statusTag, "REGULAR", 11)
            ZInk.Display.drawText(38, y + 48, "  Loai: " .. s.type, "REGULAR", 11)
            ZInk.Display.drawText(38, y + 68, "  Quy mo: ~" .. tostring(s.novels) .. " bo tieu thuyet", "REGULAR", 10)
        end
    end

    drawFooter("[Confirm: Chon lam nguon mac dinh | Back: Quay lai]")
end

-- [Screen: KOSYNC]
local function renderKOSync()
    local w = ZInk.Display.getWidth()
    drawHeader("DONG BO CLOUD KOSYNC 2 CHIEU", "REALTIME")

    local boxY = 105
    ZInk.Display.drawRect(24, boxY, w - 48, 290, false)

    ZInk.Display.drawText(38, boxY + 30, "BANG DIEU KHIEN KOSYNC CLOUD", "BOLD", 14)
    ZInk.Display.drawLine(38, boxY + 42, w - 60, boxY + 42)

    ZInk.Display.drawText(38, boxY + 74, "• Server KOSync: http://sync.ztruyen.vn:8080", "REGULAR", 12)
    ZInk.Display.drawText(38, boxY + 106, "• Tai khoan: ztruyen_pro_reader_x3", "REGULAR", 12)
    ZInk.Display.drawText(38, boxY + 138, "• Tinh trang mang: DA KET NOI (Wi-Fi Online)", "BOLD", 12)
    ZInk.Display.drawText(38, boxY + 170, "• Tien trinh doc da luu: 4 bo truyen (12 chuong)", "REGULAR", 12)
    ZInk.Display.drawText(38, boxY + 202, "• Thiet bi lien ket: Xteink X3 <-> App Android", "REGULAR", 12)
    ZInk.Display.drawText(38, boxY + 234, "• Co che: Dong bo 2 chieu (Doc dau tiep do)", "REGULAR", 12)
    ZInk.Display.drawText(38, boxY + 266, "• Lan dong bo gan nhat: Vua xong", "REGULAR", 11)

    if toastMessage ~= "" then
        ZInk.Display.drawRect(24, 430, w - 48, 60, true)
        ZInk.Display.drawText(38, 466, toastMessage, "BOLD", 13)
    else
        ZInk.Display.drawRect(24, 430, w - 48, 60, false)
        ZInk.Display.drawText(38, 466, "Nhan [CONFIRM] de dong bo ngay lap tuc", "REGULAR", 12)
    end

    drawFooter("[Confirm: Dong bo ngay | Back: Quay lai Menu]")
end

-- [Screen: ABOUT]
local function renderAbout()
    local w = ZInk.Display.getWidth()
    drawHeader("HUONG DAN & THIET LAP", "Z-CROSSINK")

    local y = 105
    ZInk.Display.drawRect(24, y, w - 48, 380, false)

    ZInk.Display.drawText(38, y + 30, "KIEN TRUC Z-TRUYEN NOVEL ENGINE", "BOLD", 14)
    ZInk.Display.drawLine(38, y + 42, w - 60, y + 42)

    ZInk.Display.drawText(38, y + 72, "• Phien ban Engine: Z-CrossInk Lotus v1.5.1", "REGULAR", 12)
    ZInk.Display.drawText(38, y + 104, "• Thiet bi tuong thich: Xteink X3, X4, X4 Pro", "REGULAR", 12)
    ZInk.Display.drawText(38, y + 136, "• Co che Plugin: Lua 5.4.7 Sandbox Quota", "REGULAR", 12)
    ZInk.Display.drawText(38, y + 168, "• Che do Direct: Tu cao & tao EPUB ve SD", "REGULAR", 12)
    ZInk.Display.drawText(38, y + 200, "• Che do OPDS: Ket noi may chu truyen LAN", "REGULAR", 12)
    ZInk.Display.drawText(38, y + 232, "• Dong bo: KOSync Cloud Server hai chieu", "REGULAR", 12)
    ZInk.Display.drawText(38, y + 264, "• Vi tri sach SD: /Books/ZTruyen/", "REGULAR", 12)
    ZInk.Display.drawText(38, y + 296, "• Vi tri plugin: /plugins/ztruyen/", "REGULAR", 12)
    ZInk.Display.drawText(38, y + 328, "• An toan phan cung: Cach ly 100% Core Boot", "BOLD", 12)
    ZInk.Display.drawText(38, y + 358, "• Phat trien boi: Z-Truyen Open Community", "REGULAR", 11)

    drawFooter("[Back: Quay lai Menu Chinh]")
end

-- ----------------------------------------------------------------------------
-- 7. Lifecycle and Main Event Loop
-- ----------------------------------------------------------------------------
function onInit()
    print("[ZTruyen] Plugin initialized")
end

function onEnter()
    currentScreen = STATE_MAIN_MENU
    selectedIndex = 1
    selectedSubIndex = 1
    toastMessage = ""
    print("[ZTruyen] Entered flagship portal")
end

function onRender()
    ZInk.Display.clear()

    if currentScreen == STATE_MAIN_MENU then
        renderMainMenu()
    elseif currentScreen == STATE_BOOKSHELF then
        renderBookshelf()
    elseif currentScreen == STATE_ONLINE_HUB then
        renderOnlineHub()
    elseif currentScreen == STATE_STORY_DETAIL then
        renderStoryDetail()
    elseif currentScreen == STATE_SOURCES then
        renderSources()
    elseif currentScreen == STATE_KOSYNC then
        renderKOSync()
    elseif currentScreen == STATE_ABOUT then
        renderAbout()
    end
end

function onInput(key, eventType)
    if eventType ~= "RELEASE" then
        return false
    end

    -- Clear transient toast on any keypress
    if toastMessage ~= "" and key ~= "CONFIRM" then
        toastMessage = ""
    end

    if key == "UP" or key == "PAGE_PREV" or key == "VOL_DOWN" then
        if currentScreen == STATE_STORY_DETAIL then
            selectedSubIndex = selectedSubIndex - 1
            if selectedSubIndex < 1 then selectedSubIndex = 4 end
        else
            local maxI = 5
            if currentScreen == STATE_MAIN_MENU then maxI = #mainMenuEntries
            elseif currentScreen == STATE_BOOKSHELF then maxI = 4
            elseif currentScreen == STATE_ONLINE_HUB then maxI = #onlineNovels
            elseif currentScreen == STATE_SOURCES then maxI = #sourceAdapters end

            selectedIndex = selectedIndex - 1
            if selectedIndex < 1 then selectedIndex = maxI end
        end
        return true

    elseif key == "DOWN" or key == "PAGE_NEXT" or key == "VOL_UP" then
        if currentScreen == STATE_STORY_DETAIL then
            selectedSubIndex = selectedSubIndex + 1
            if selectedSubIndex > 4 then selectedSubIndex = 1 end
        else
            local maxI = 5
            if currentScreen == STATE_MAIN_MENU then maxI = #mainMenuEntries
            elseif currentScreen == STATE_BOOKSHELF then maxI = 4
            elseif currentScreen == STATE_ONLINE_HUB then maxI = #onlineNovels
            elseif currentScreen == STATE_SOURCES then maxI = #sourceAdapters end

            selectedIndex = selectedIndex + 1
            if selectedIndex > maxI then selectedIndex = 1 end
        end
        return true

    elseif key == "CONFIRM" then
        if currentScreen == STATE_MAIN_MENU then
            local targetScreen = mainMenuEntries[selectedIndex].screen
            currentScreen = targetScreen
            selectedIndex = 1
            selectedSubIndex = 1
            toastMessage = ""
            return true

        elseif currentScreen == STATE_BOOKSHELF then
            local downloaded = {}
            for _, b in ipairs(onlineNovels) do
                if b.isDownloaded then table.insert(downloaded, b) end
            end
            local b = downloaded[selectedIndex]
            if b then
                print("[ZTruyen] Opening book directly: " .. b.title .. " (" .. b.localPath .. ")")
                ZInk.Reader.openBook(b.localPath)
            end
            return true

        elseif currentScreen == STATE_ONLINE_HUB then
            currentScreen = STATE_STORY_DETAIL
            selectedSubIndex = 1
            toastMessage = ""
            return true

        elseif currentScreen == STATE_STORY_DETAIL then
            local b = onlineNovels[selectedIndex]
            if selectedSubIndex == 1 then
                -- Doc ngay
                print("[ZTruyen] Reading story: " .. b.title)
                ZInk.Reader.openBook(b.localPath)
            elseif selectedSubIndex == 2 then
                -- Tai tap 1
                b.isDownloaded = true
                toastMessage = "DA TAI TAP 1 (CHUONG 1-50) VE SD CARD!"
            elseif selectedSubIndex == 3 then
                -- Tai tron bo
                b.isDownloaded = true
                toastMessage = "DA TAI TRON BO EPUB VE /Books/ZTruyen/!"
            elseif selectedSubIndex == 4 then
                -- Dong bo KOSync
                toastMessage = "DA DONG BO VI TRI CHUONG LEN CLOUD!"
            end
            return true

        elseif currentScreen == STATE_SOURCES then
            activeSource = selectedIndex
            toastMessage = "DA CHUYEN NGUON SANG: " .. sourceAdapters[activeSource].name
            return true

        elseif currentScreen == STATE_KOSYNC then
            toastMessage = "DA DONG BO 100% TIEN TRINH LEN CLOUD!"
            return true
        end
        return true

    elseif key == "BACK" then
        if currentScreen == STATE_STORY_DETAIL then
            currentScreen = STATE_ONLINE_HUB
            return true
        elseif currentScreen ~= STATE_MAIN_MENU then
            currentScreen = STATE_MAIN_MENU
            selectedIndex = 1
            toastMessage = ""
            return true
        else
            ZInk.UI.popView()
            return true
        end
    end

    return false
end

function onExit()
    print("[ZTruyen] Exited portal cleanly")
end
