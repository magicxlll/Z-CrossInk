-- ========================================================
-- MINIMAL HELLO WORLD PLUGIN (PHASE P1 REFERENCE)
-- Standard: Z-Plugin Specification v1.0
-- Target: Xteink X3 (528x792)
-- ========================================================

local clickCount = 0
local lastAction = "Chua co thao tac"
local statusMessage = "He thong Plugin Sandbox hoat dong binh thuong."

function onInit()
    print("[HelloPlugin] onInit() called")
end

function onEnter()
    print("[HelloPlugin] onEnter() called")
    clickCount = 0
    lastAction = "Khoi dong plugin thanh cong"
end

function onRender()
    local w = ZInk.Display.getWidth()
    local h = ZInk.Display.getHeight()

    ZInk.Display.clear()

    -- 1. Header Card
    ZInk.Display.drawRect(20, 20, w - 40, 56, false)
    ZInk.Display.drawText(36, 56, "HELLO WORLD - Z-CROSSINK", "BOLD", 16)
    ZInk.Display.drawText(w - 120, 56, "v1.0.0", "REGULAR", 12)
    ZInk.Display.drawLine(20, 86, w - 40, 86)

    -- 2. Status Banner Box
    local bannerY = 110
    ZInk.Display.drawRect(24, bannerY, w - 48, 80, false)
    ZInk.Display.drawText(38, bannerY + 32, "PLUGIN SANDBOX REFERENCE", "BOLD", 14)
    ZInk.Display.drawText(38, bannerY + 60, statusMessage, "REGULAR", 12)

    -- 3. Interactive Counter Box
    local boxY = 215
    ZInk.Display.drawRect(24, boxY, w - 48, 120, true)
    ZInk.Display.drawText(38, boxY + 36, "SO LAN BAM PHIM (CLICKS): " .. tostring(clickCount), "BOLD", 16)
    ZInk.Display.drawText(38, boxY + 70, "Phim gan nhat: " .. lastAction, "REGULAR", 13)
    ZInk.Display.drawText(38, boxY + 100, "RAM Heap con lai: " .. tostring(ZInk.System.getFreeHeap()) .. " bytes", "REGULAR", 11)

    -- 4. Architecture Info Box
    local infoY = 360
    ZInk.Display.drawRect(24, infoY, w - 48, 180, false)
    ZInk.Display.drawText(38, infoY + 30, "THONG TIN HE DONG HANH & HE PHAN:", "BOLD", 13)
    ZInk.Display.drawLine(38, infoY + 38, 320, infoY + 38)
    ZInk.Display.drawText(38, infoY + 68, "• Nen tang: CrossInk v1.5.1 Base", "REGULAR", 12)
    ZInk.Display.drawText(38, infoY + 98, "• Plugin Engine: Z-Lua 5.4.7 Sandbox", "REGULAR", 12)
    ZInk.Display.drawText(38, infoY + 128, "• Thiet bi muc tieu: Xteink X3 (ESP32-C3)", "REGULAR", 12)
    ZInk.Display.drawText(38, infoY + 158, "• An toan phan cung: Cach ly 100% Core HAL", "REGULAR", 12)

    -- 5. Footer Navigation Hints
    local footY = h - 60
    ZInk.Display.drawLine(20, footY, w - 40, footY)
    ZInk.Display.drawText(30, footY + 36, "[UP/DOWN/CONFIRM: Tang dem | BACK: Thoat an toan]", "REGULAR", 10)
end

function onInput(key, eventType)
    if eventType ~= "RELEASE" then
        return false
    end

    if key == "UP" then
        clickCount = clickCount + 1
        lastAction = "Phim UP (Len)"
        return true
    elseif key == "DOWN" then
        clickCount = clickCount + 1
        lastAction = "Phim DOWN (Xuong)"
        return true
    elseif key == "CONFIRM" then
        clickCount = clickCount + 1
        lastAction = "Phim CONFIRM (Chon)"
        return true
    elseif key == "LEFT" then
        clickCount = clickCount + 1
        lastAction = "Phim LEFT (Trai)"
        return true
    elseif key == "RIGHT" then
        clickCount = clickCount + 1
        lastAction = "Phim RIGHT (Phai)"
        return true
    elseif key == "BACK" then
        print("[HelloPlugin] BACK button pressed -> exiting")
        ZInk.UI.popView()
        return true
    end

    return false
end

function onExit()
    print("[HelloPlugin] onExit() completed cleanly")
end
