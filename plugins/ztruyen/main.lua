-- ========================================================
-- Z-Truyen Pro E-ink Portal (Flagship Plugin for Z-CrossInk)
-- Target: Xteink X3 (528x792 E-ink Screen)
-- ========================================================

local selectedIndex = 1
local menuItems = {
    { title = "1. Doc Tiep Chuong Gan Nhat", action = "RESUME" },
    { title = "2. Truyen Moi Cap Nhat", action = "NEWEST" },
    { title = "3. Tim Kiem Truyen", action = "SEARCH" },
    { title = "4. Dong Bo Tien Trinh KOSync", action = "KOSYNC" },
    { title = "5. Huong Dan & Thiet Lap", action = "SETTINGS" }
}

function onEnter()
    selectedIndex = 1
    print("[Z-Truyen Plugin] Entered portal UI")
end

function onRender()
    local w = ZInk.Display.getWidth()
    local h = ZInk.Display.getHeight()

    -- 1. Clear Screen
    ZInk.Display.clear()

    -- 2. Header Banner
    ZInk.Display.drawRect(20, 25, w - 40, 50, false)
    ZInk.Display.drawText(35, 60, "Z-TRUYEN PRO  •  E-INK EDITION", "BOLD", 16)
    ZInk.Display.drawLine(20, 85, w - 40, 85)

    -- 3. Render Menu Options
    local startY = 120
    local itemHeight = 65

    for i, item in ipairs(menuItems) do
        local y = startY + (i - 1) * itemHeight
        local isSelected = (i == selectedIndex)

        if isSelected then
            -- Highlight box for selected item
            ZInk.Display.drawRect(25, y, w - 50, 50, true)
            ZInk.Display.drawText(45, y + 33, "> " .. item.title, "BOLD", 14)
        else
            ZInk.Display.drawRect(25, y, w - 50, 50, false)
            ZInk.Display.drawText(45, y + 33, "  " .. item.title, "REGULAR", 14)
        end
    end

    -- 4. Footer Guide
    local footerY = h - 60
    ZInk.Display.drawLine(20, footerY, w - 40, footerY)
    ZInk.Display.drawText(30, footerY + 35, "[Len/Xuong: Chon | Confirm: Mo | Back: Thoat]", "REGULAR", 10)
end

function onInput(key, eventType)
    if eventType ~= "RELEASE" then
        return false
    end

    if key == "UP" or key == "LEFT" or key == "VOL_DOWN" then
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then selectedIndex = #menuItems end
        return true
    elseif key == "DOWN" or key == "RIGHT" or key == "VOL_UP" then
        selectedIndex = selectedIndex + 1
        if selectedIndex > #menuItems then selectedIndex = 1 end
        return true
    elseif key == "CONFIRM" then
        local item = menuItems[selectedIndex]
        if item.action == "RESUME" then
            print("[Z-Truyen Plugin] Resuming reading...")
        elseif item.action == "KOSYNC" then
            print("[Z-Truyen Plugin] Starting KOSync bi-directional sync...")
        end
        return true
    elseif key == "BACK" then
        ZInk.UI.popView()
        return true
    end

    return false
end

function onExit()
    print("[Z-Truyen Plugin] Exited portal UI")
end
