if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remoteGet = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
local remotePost = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("POST")

print("🚀 [" .. player.Name .. "] เปิดใช้งานระบบสุ่มตระกูลอัตโนมัติแล้ว!")

getgenv().HorstConfig = {
    ["EnableLog"] = true,
    ["Whitescreen"] = false,
    ["EnableAddFriends"] = false,
    ["LockFps"] = { ["EnableLockFps"] = false, ["LockFpsAmount"] = 10 }
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()

local VirtualUser = game:GetService("VirtualUser")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local GOOGLE_SHEET_WEBAPP_URL = "https://script.google.com/macros/s/AKfycbyHGeI06oEJfPXldfV56mTCpvP-pHKr5Ft-6WkeGkEc8GeOp_oVXBclM0qfJjeu71Kk/exec"
local GLOBAL_LATEST_SPINS = 0

local TARGET_FAMILIES = {
    ["fritz"] = "mythical",
    ["helos"] = "mythical",
    ["ackerman"] = "legendary",
    ["reiss"] = "legendary",
    ["yeager"] = "legendary"
}

local familyStats = { ["fritz"] = 0, ["helos"] = 0, ["ackerman"] = 0, ["reiss"] = 0, ["yeager"] = 0 }

local function sendToGoogleSheet(familyName, familyGroup, currentSpin)
    if GOOGLE_SHEET_WEBAPP_URL == "" then return end
    pcall(function()
        local payload = { ["account"] = player.Name, ["family"] = familyName, ["tier"] = familyGroup, ["spins"] = currentSpin, ["timestamp"] = os.date("%Y-%m-%d %H:%M:%S") }
        local req = (syn and syn.request) or (http and http.request) or request or HttpService.RequestAsync
        if req then req({ Url = GOOGLE_SHEET_WEBAPP_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload) }) end
    end)
end

local function updateHorstPanel(spinsRemaining)
    pcall(function()
        if _G.Horst_SetDescription then
            local totalM = familyStats["fritz"] + familyStats["helos"]
            local totalL = familyStats["ackerman"] + familyStats["reiss"] + familyStats["yeager"]
            local message = string.format("🎲 Spins: %d  Mythic: %d/5 (F:%d H:%d)  Legend: %d/1 (A:%d R:%d Y:%d)", spinsRemaining, totalM, familyStats["fritz"], familyStats["helos"], totalL, familyStats["ackerman"], familyStats["reiss"], familyStats["yeager"])
            _G.Horst_SetDescription(message)
        end
    end)
end

local function buySpinsOneTime()
    local shopTiers = { {tier = 5, cost = 45000}, {tier = 4, cost = 23000}, {tier = 3, cost = 10000}, {tier = 2, cost = 2500}, {tier = 1, cost = 500} }
    for _, item in ipairs(shopTiers) do
        pcall(function() remoteGet:InvokeServer("S_Market", "Buy", "Spins", item.tier, 1) end)
        task.wait(0.3)
    end
end

local function startRollingProcess()
    print("🎲 [" .. player.Name .. "] เริ่มลูปสุ่มตระกูล...")
    while true do
        local totalMythical = familyStats["fritz"] + familyStats["helos"]
        local totalLegendary = familyStats["ackerman"] + familyStats["reiss"] + familyStats["yeager"]
        if totalMythical >= 5 and totalLegendary >= 1 then
            if _G.Horst_AccountChangeDone then _G.Horst_AccountChangeDone() end
            break 
        end

        local rawData = { pcall(remoteGet.InvokeServer, remoteGet, "Family", "Roll") }
        if rawData[1] == true and #rawData > 1 then
            local currentFamily = tostring(rawData[4] or "")
            local currentSpin = (tonumber(rawData[2]) or 0) + (tonumber(rawData[3]) or 0)
            GLOBAL_LATEST_SPINS = currentSpin
            updateHorstPanel(currentSpin)
            
            if currentFamily ~= "" and currentFamily ~= "0" then
                local lowerName = string.lower(currentFamily)
                for targetKey, group in pairs(TARGET_FAMILIES) do
                    if string.find(lowerName, targetKey) then
                        local shouldStore = (group == "mythical" and totalMythical < 5) or (group == "legendary" and totalLegendary < 1)
                        if shouldStore then
                            remoteGet:InvokeServer("Family", "Store")
                            familyStats[targetKey] = familyStats[targetKey] + 1
                            sendToGoogleSheet(currentFamily, group, currentSpin)
                        end
                    end
                end
            end
            task.wait(3.5)
        else
            task.wait(3)
        end
    end
end

task.wait(2)
buySpinsOneTime()
startRollingProcess()