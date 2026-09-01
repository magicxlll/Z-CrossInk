-- ========================================================
-- SUDOKU ZEN E-INK (Z-CROSSINK COMMUNITY PLUGIN)
-- Optimized for Xteink X3 528x792 Screen
-- ========================================================

local cursorX = 1
local cursorY = 1
local currentLevel = 1 -- 1: De, 2: Trung Binh, 3: Kho
local selectedNumber = 1
local isNoteMode = false
local messageText = "Su dung phim mui ten de di chuyen, CONFIRM de nhap so."

-- Bang cau do Sudoku mau
local PUZZLES = {
    -- Level 1: De
    {
        initial = {
            {5,3,0, 0,7,0, 0,0,0},
            {6,0,0, 1,9,5, 0,0,0},
            {0,9,8, 0,0,0, 0,6,0},

            {8,0,0, 0,6,0, 0,0,3},
            {4,0,0, 8,0,3, 0,0,1},
            {7,0,0, 0,2,0, 0,0,6},

            {0,6,0, 0,0,0, 2,8,0},
            {0,0,0, 4,1,9, 0,0,5},
            {0,0,0, 0,8,0, 0,7,9}
        },
        solution = {
            {5,3,4, 6,7,8, 9,1,2},
            {6,7,2, 1,9,5, 3,4,8},
            {1,9,8, 3,4,2, 5,6,7},

            {8,5,9, 7,6,1, 4,2,3},
            {4,2,6, 8,5,3, 7,9,1},
            {7,1,3, 9,2,4, 8,5,6},

            {9,6,1, 5,3,7, 2,8,4},
            {2,8,7, 4,1,9, 6,3,5},
            {3,4,5, 2,8,6, 1,7,9}
        }
    },
    -- Level 2: Trung Binh
    {
        initial = {
            {0,0,0, 6,0,0, 4,0,0},
            {7,0,0, 0,0,3, 6,0,0},
            {0,0,0, 0,9,1, 0,8,0},

            {0,0,0, 0,0,0, 0,0,0},
            {0,5,0, 1,8,0, 0,0,3},
            {0,0,0, 3,0,6, 0,4,5},

            {0,4,0, 2,0,0, 0,6,0},
            {9,0,3, 0,0,0, 0,0,0},
            {0,2,0, 0,0,0, 1,0,0}
        },
        solution = {
            {5,8,1, 6,7,2, 4,3,9},
            {7,9,2, 8,4,3, 6,5,1},
            {3,6,4, 5,9,1, 7,8,2},

            {4,3,8, 9,5,7, 2,1,6},
            {2,5,6, 1,8,4, 9,7,3},
            {1,7,9, 3,2,6, 8,4,5},

            {8,4,5, 2,1,9, 3,6,7},
            {9,1,3, 7,6,8, 5,2,4},
            {6,2,7, 4,3,5, 1,9,8}
        }
    }
}

local board = {}
local isInitial = {}

local function loadPuzzle(lvl)
    currentLevel = lvl
    local p = PUZZLES[lvl]
    board = {}
    isInitial = {}
    for r = 1, 9 do
        board[r] = {}
        isInitial[r] = {}
        for c = 1, 9 do
            local val = p.initial[r][c]
            board[r][c] = val
            isInitial[r][c] = (val ~= 0)
        end
    end
    messageText = "Da nạp ban co moi (Cap do " .. tostring(lvl) .. ")"
end

local function checkWin()
    local p = PUZZLES[currentLevel]
    for r = 1, 9 do
        for c = 1, 9 do
            if board[r][c] ~= p.solution[r][c] then
                return false
            end
        end
    end
    return true
end

function onEnter()
    loadPuzzle(1)
end

function onRender()
    ZInk.Display.clear()

    -- 1. Header Bar
    ZInk.Display.drawRect(20, 20, 488, 56, true)
    ZInk.Display.drawText(40, 38, "SUDOKU ZEN E-INK", 14)
    local lvlStr = currentLevel == 1 and "De" or "Trung Binh"
    ZInk.Display.drawText(360, 40, "[" .. lvlStr .. "]", 12)

    -- 2. Ve luoi 9x9 (Toa do: X=45, Y=100, moi o 48x48)
    local startX = 48
    local startY = 100
    local cellSize = 48

    for r = 1, 9 do
        for c = 1, 9 do
            local x = startX + (c - 1) * cellSize
            local y = startY + (r - 1) * cellSize

            -- Highlight con tro
            if r == cursorY and c == cursorX then
                ZInk.Display.drawRect(x + 2, y + 2, cellSize - 4, cellSize - 4, true)
            else
                ZInk.Display.drawRect(x, y, cellSize, cellSize, false)
            end

            -- Ve so
            local val = board[r][c]
            if val and val > 0 then
                local numStr = tostring(val)
                local textX = x + 18
                local textY = y + 14
                ZInk.Display.drawText(textX, textY, numStr, 14)
            end
        end
    end

    -- 3. Ve cac duong vien 3x3 dam
    for i = 0, 3 do
        local offset = i * (cellSize * 3)
        -- Duong doc
        ZInk.Display.drawRect(startX + offset - 1, startY, 3, cellSize * 9, true)
        -- Duong ngang
        ZInk.Display.drawRect(startX, startY + offset - 1, cellSize * 9, 3, true)
    end

    -- 4. Thanh chon so ben duoi
    local numBarY = startY + (cellSize * 9) + 24
    ZInk.Display.drawText(startX, numBarY, "Chon so: ", 12)
    for n = 1, 9 do
        local nx = startX + 70 + (n - 1) * 36
        if n == selectedNumber then
            ZInk.Display.drawRect(nx - 4, numBarY - 4, 30, 30, true)
        else
            ZInk.Display.drawRect(nx - 4, numBarY - 4, 30, 30, false)
        end
        ZInk.Display.drawText(nx + 6, numBarY + 2, tostring(n), 12)
    end

    -- 5. Footer & Huong dan
    local footerY = numBarY + 50
    ZInk.Display.drawRect(20, footerY, 488, 120, false)
    ZInk.Display.drawText(36, footerY + 16, messageText, 10)
    ZInk.Display.drawText(36, footerY + 45, "[ARROWS]: Di chuyen o        [CONFIRM]: Dat so", 10)
    ZInk.Display.drawText(36, footerY + 75, "[LEFT+RIGHT]: Doi so chon    [BACK]: Thoat", 10)
end

function onInput(button, action)
    if action == "RELEASE" then
        if button == "UP" then
            if cursorY > 1 then cursorY = cursorY - 1 end
            return true
        elseif button == "DOWN" then
            if cursorY < 9 then cursorY = cursorY + 1 end
            return true
        elseif button == "LEFT" then
            if cursorX > 1 then 
                cursorX = cursorX - 1 
            else
                -- Doi so dang chon
                selectedNumber = selectedNumber > 1 and selectedNumber - 1 or 9
            end
            return true
        elseif button == "RIGHT" then
            if cursorX < 9 then 
                cursorX = cursorX + 1 
            else
                -- Doi so dang chon
                selectedNumber = selectedNumber < 9 and selectedNumber + 1 or 1
            end
            return true
        elseif button == "CONFIRM" then
            if not isInitial[cursorY][cursorX] then
                if board[cursorY][cursorX] == selectedNumber then
                    board[cursorY][cursorX] = 0 -- Xoa neu bam lai cung so
                    messageText = "Da xoa so tai o (" .. cursorY .. "," .. cursorX .. ")"
                else
                    board[cursorY][cursorX] = selectedNumber
                    messageText = "Dat so " .. selectedNumber .. " vao o (" .. cursorY .. "," .. cursorX .. ")"
                    if checkWin() then
                        messageText = "CHUC MUNG! BAN DA GIAI THANH CONG SUDOKU!"
                    end
                end
            else
                messageText = "O nay la so mac dinh, khong the sua!"
            end
            return true
        elseif button == "BACK" then
            ZInk.UI.popView()
            return true
        end
    end
    return false
end

function onExit()
    -- Luu game neu can
end
