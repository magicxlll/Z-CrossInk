-- ========================================================
-- LICH VAN NIEN & AM LICH VIET NAM (Z-CROSSINK PLUGIN)
-- Optimized for Xteink X3 528x792 E-ink Screen
-- ========================================================

local currentYear = 2026
local currentMonth = 9
local currentDay = 1

local CAN = {"Giap", "At", "Binh", "Dinh", "Mau", "Ky", "Canh", "Tan", "Nham", "Quy"}
local CHI = {"Ty", "Suu", "Dan", "Mao", "Thin", "Ty", "Ngo", "Mui", "Than", "Dau", "Tuat", "Hoi"}

local QUOTES = {
    "Sach la ngon den sang soi con duong tri thuc cua nhan loai.",
    "Moi trang sach mo ra mot chan troi moi.",
    "Doc sach khong chi de biet, ma de thau hieu va yeu thuong.",
    "Nguoi doc sach song hang ngan cuoc doi truoc khi qua doi.",
    "Khong co nguoi ban nao trung thanh va uyen bac bang mot cuon sach hay.",
    "Dau tu vao tri thuc luon mang lai loi nhuan cao nhat."
}

local function getCanChiYear(year)
    local canIdx = ((year - 4) % 10) + 1
    local chiIdx = ((year - 4) % 12) + 1
    return CAN[canIdx] .. " " .. CHI[chiIdx]
end

local function getDaysInMonth(year, month)
    if month == 2 then
        if (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0) then
            return 29
        else
            return 28
        end
    elseif month == 4 or month == 6 or month == 9 or month == 11 then
        return 30
    else
        return 31
    end
end

-- Cong thuc Zeller tinh thu trong tuan (0: Chu Nhat, 1: Thu 2, ...)
local function getDayOfWeek(year, month, day)
    local m = month
    local y = year
    if m < 3 then
        m = m + 12
        y = y - 1
    end
    local k = y % 100
    local j = math.floor(y / 100)
    local h = (day + math.floor((13 * (m + 1)) / 5) + k + math.floor(k / 4) + math.floor(j / 4) - 2 * j) % 7
    local dow = (h + 5) % 7 + 1 -- 1: T2, 2: T3, ..., 7: CN
    return dow
end

function onEnter()
    print("Lich Van Nien E-ink khoi dong.")
end

function onRender()
    ZInk.Display.clear()

    -- 1. Header Bar
    ZInk.Display.drawRect(20, 20, 488, 56, true)
    ZInk.Display.drawText(40, 38, "LICH VAN NIEN & AM LICH", 14)
    ZInk.Display.drawText(360, 40, tostring(currentMonth) .. "/" .. tostring(currentYear), 12)

    -- 2. Thong tin Ngay Lon
    local boxY = 90
    ZInk.Display.drawRect(20, boxY, 488, 140, false)
    
    local dayStr = (currentDay < 10 and "0" or "") .. tostring(currentDay)
    ZInk.Display.drawText(40, boxY + 20, "NGAY", 12)
    ZInk.Display.drawText(40, boxY + 50, dayStr, 18)
    
    local dowNames = {"Thu Hai", "Thu Ba", "Thu Tu", "Thu Nam", "Thu Sau", "Thu Bay", "Chu Nhat"}
    local dow = getDayOfWeek(currentYear, currentMonth, currentDay)
    ZInk.Display.drawText(160, boxY + 25, dowNames[dow] .. " - Thang " .. currentMonth .. " Nam " .. currentYear, 12)
    
    -- Am Lich uoc tinh
    local canChiNam = getCanChiYear(currentYear)
    local amNgay = ((currentDay + 20) % 30) + 1
    local amThang = (currentMonth + 10) % 12 + 1
    ZInk.Display.drawText(160, boxY + 60, "Am lich: Ngay " .. amNgay .. " Thang " .. amThang .. " (Nam " .. canChiNam .. ")", 12)
    ZInk.Display.drawText(160, boxY + 95, "Hoang dao: Thanh Long, Minh Duong, Kim Quy", 10)

    -- 3. Bang Lich Thang (7 cot x 6 dong)
    local calY = 245
    local cellW = 68
    local cellH = 46
    local calStartX = 26

    -- Header thu
    local dayHeaders = {"T2", "T3", "T4", "T5", "T6", "T7", "CN"}
    for i = 1, 7 do
        local hx = calStartX + (i - 1) * cellW
        ZInk.Display.drawRect(hx, calY, cellW, 30, true)
        ZInk.Display.drawText(hx + 22, calY + 8, dayHeaders[i], 10)
    end

    local firstDow = getDayOfWeek(currentYear, currentMonth, 1)
    local totalDays = getDaysInMonth(currentYear, currentMonth)
    local curCol = firstDow
    local curRow = 1

    for d = 1, totalDays do
        local dx = calStartX + (curCol - 1) * cellW
        local dy = calY + 32 + (curRow - 1) * cellH

        if d == currentDay then
            ZInk.Display.drawRect(dx + 2, dy + 2, cellW - 4, cellH - 4, true)
            ZInk.Display.drawText(dx + 24, dy + 14, tostring(d), 12)
        else
            ZInk.Display.drawRect(dx, dy, cellW, cellH, false)
            local dStr = tostring(d)
            local padX = d < 10 and 26 or 20
            ZInk.Display.drawText(dx + padX, dy + 14, dStr, 12)
        end

        curCol = curCol + 1
        if curCol > 7 then
            curCol = 1
            curRow = curRow + 1
        end
    end

    -- 4. Danh ngon doc sach
    local quoteY = 570
    ZInk.Display.drawRect(20, quoteY, 488, 110, false)
    ZInk.Display.drawText(36, quoteY + 16, "DANH NGON DOC SACH:", 10)
    local quoteIdx = (currentDay % #QUOTES) + 1
    ZInk.Display.drawText(36, quoteY + 45, QUOTES[quoteIdx], 10)

    -- 5. Footer dieu huong
    local footerY = 695
    ZInk.Display.drawRect(20, footerY, 488, 70, true)
    ZInk.Display.drawText(36, footerY + 16, "[LEFT / RIGHT]: Chuyen ngay / thang", 10)
    ZInk.Display.drawText(36, footerY + 40, "[CONFIRM]: Hom nay           [BACK]: Thoat", 10)
end

function onInput(button, action)
    if action == "RELEASE" then
        if button == "LEFT" then
            if currentDay > 1 then
                currentDay = currentDay - 1
            else
                currentMonth = currentMonth > 1 and currentMonth - 1 or 12
                if currentMonth == 12 then currentYear = currentYear - 1 end
                currentDay = getDaysInMonth(currentYear, currentMonth)
            end
            return true
        elseif button == "RIGHT" then
            local maxDays = getDaysInMonth(currentYear, currentMonth)
            if currentDay < maxDays then
                currentDay = currentDay + 1
            else
                currentMonth = currentMonth < 12 and currentMonth + 1 or 1
                if currentMonth == 1 then currentYear = currentYear + 1 end
                currentDay = 1
            end
            return true
        elseif button == "CONFIRM" then
            currentYear = 2026
            currentMonth = 9
            currentDay = 1
            return true
        elseif button == "BACK" then
            ZInk.UI.popView()
            return true
        end
    end
    return false
end

function onExit()
    -- Clean up
end
