if not game:IsLoaded() then
    game.Loaded:Wait()
end

if _G.IsPipelineRunning then return end
_G.IsPipelineRunning = true

task.wait(5)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remoteGet = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
local remotePost = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("POST")

-- 📌 ตรงนี้ให้นำลิงก์ Raw ของไฟล์ spin.lua มาใส่แทนข้อความด้านล่างนี้
local SPIN_SCRIPT_URL = "https://raw.githubusercontent.com/koonfat02-oss/roblox-automation/refs/heads/main/spin.lua?token=GHSAT0AAAAAAEKEJVBTALTCVYIF63AKBGUU2V7IEVA"

-- ฟังก์ชันเช็กสถานะ Slot B และ C
local function checkCurrentSlots()
    local statusB, statusC = "❌", "❌"
    pcall(function()
        local slotsFolder = playerGui.Interface.Title_Screen.Slots
        local slotB, slotC = slotsFolder:FindFirstChild("B"), slotsFolder:FindFirstChild("C")
        
        if slotB then
            if slotB:FindFirstChild("Select_B") then statusB = "✅" end
        end
        if slotC then
            if slotC:FindFirstChild("Select_C") then statusC = "✅" end
        end
    end)
    return statusB, statusC
end

-- 1. เช็กตั้งแต่หน้าเมนูรอบแรก
local slotB_Status, slotC_Status = checkCurrentSlots()

if slotB_Status == "✅" and slotC_Status == "✅" then
    print("👑 Slot ครบตั้งแต่แรก! เปิดไฟล์สุ่มตระกูลทันที")
    _G.IsPipelineRunning = nil
    loadstring(game:HttpGet(SPIN_SCRIPT_URL))()
    return
end

print("⏳ Slot ยังไม่ครบ กำลังพาเข้า Slot A ไปกวาดเควส...")

-- 2. โค้ดที่จะรันต่อหลังวาร์ปไปทำเควสแล้ววาร์ปกลับมาหน้า Menu
local nextStepCode = [[
    _G.IsPipelineRunning = nil
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local remoteGet = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
    local remotePost = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("POST")
    local SPIN_URL =]] .. '"' .. SPIN_SCRIPT_URL .. '"' .. [[

    task.wait(8) -- รอโหลดเข้า Lobby

    print("--- เริ่มกวาดเควสทั้งหมด ---")
    pcall(function()
        local questStorage = require(ReplicatedStorage.Modules.Storage.Quest)
        for catName, catData in pairs(questStorage) do
            if catData.Quests then
                for _, q in ipairs(catData.Quests) do
                    if q.Tag then
                        pcall(function() remoteGet:InvokeServer("Functions", "Quest", q.Tag, catName) end)
                        task.wait(0.05)
                    end
                end
            end
        end
    end)

    task.wait(2)
    print("--- วาร์ปกลับหน้า Menu เพื่อเช็กสล็อตซ้ำ ---")
    pcall(function() remotePost:FireServer("Functions", "Teleport", "Menu", nil) end)
    task.wait(6)

    local function finalCheck(slotLetter)
        local status = false
        pcall(function()
            local s = playerGui.Interface.Title_Screen.Slots:FindFirstChild(slotLetter)
            if s and s:FindFirstChild("Select_" .. slotLetter) then status = true end
        end)
        return status
    end

    if finalCheck("B") and finalCheck("C") then
        print("👑 ทำเควสปลดล็อกสำเร็จ! เริ่มรันไฟล์สุ่มตระกูลต่ออัตโนมัติ")
        loadstring(game:HttpGet(SPIN_URL))()
    else
        print("❌ สล็อตยังไม่ครบ หยุดทำงานชั่วคราว")
    end
]]

if queue_on_teleport then
    queue_on_teleport(nextStepCode)
end
task.wait(1)

-- เริ่มต้นเข้า Slot A แล้ววาร์ปเข้า Lobby
pcall(function() remoteGet:InvokeServer("Functions", "Select", "A") end)
task.wait(1)
pcall(function() remoteGet:InvokeServer("Functions", "Teleport", "Lobby", nil) end)