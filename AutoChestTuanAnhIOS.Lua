local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Phát nhạc khi bật script
local joinSound = Instance.new("Sound")
joinSound.Name = "JoinSound"
joinSound.SoundId = "rbxassetid://83142874256382"
joinSound.Volume = 3
joinSound.Looped = false
joinSound.Parent = workspace
joinSound:Play()

-- Hiển thị thông báo khi bật script
game.StarterGui:SetCore("SendNotification", {
    Title = "Tuấn Anh IOS",
    Text = "Tuấn Anh Điển Troai",  -- Tên chủ script
    Duration = 5
})

task.spawn(function()
    while true do
        game.StarterGui:SetCore("SendNotification", {
            Title = "Tuấn Anh IOS",
            Text = "Tuấn Anh DepZai Chest",  -- Tên chủ script
            Duration = 5
        })
        task.wait(10000)  -- Khoảng thời gian giữa các thông báo
    end
end)

task.spawn(function()
    require(ReplicatedStorage:WaitForChild("Notification")).new(
        " <Color=Red>Tuấn Anh Hub Chest <Color=/> "
    ):Display()
    
    require(ReplicatedStorage:WaitForChild("Notification")).new(
        " <Color=Green>Welcome to Tuấn Anh IOS Hub Loading<Color=/> "
    ):Display()
    
    require(ReplicatedStorage:WaitForChild("Notification")).new(
        " <Color=Yellow>https://Discord.gg/AkDgH65MUF<Color=/> "
    ):Display()
end)

-- Cấu hình
local MaxSpeed = 370 -- Tốc độ bay
local ChestDetectionDistance = 5000 -- Khoảng cách tối đa tìm rương
local ChestLimit = 165  -- Số rương tối đa để đổi server
local SpamChatDelay = 300 -- Delay giữa các lần chat

-- Biến để đếm số lượng rương đã nhặt
local chestsCollected = 0
local stopCollecting = false

-- Chức năng kiểm tra vật phẩm trong rương
local function checkChestItem(item)
    if game.PlaceId == 2753915549 and item == "Fist of Darkness" then -- Sea 2
        stopCollecting = true
        print("Nhặt được Fist of Darkness - Dừng nhặt rương!")
        spamChat("Nhặt được Fist of Darkness - Dừng nhặt rương!")
    elseif game.PlaceId == 4442272183 and item == "Chén Thánh" then -- Sea 3
        stopCollecting = true
        print("Nhặt được Chén Thánh - Dừng nhặt rương!")
        spamChat("Nhặt được Chén Thánh - Dừng nhặt rương!")
    end
end

-- Kiểm tra và nhặt rương
local function collectChests()
    while not stopCollecting do
        local chests = workspace:GetDescendants()
        for _, chest in ipairs(chests) do
            if chest:IsA("Part") and chest.Name:find("Chest") then
                print("Đang nhặt rương: " .. chest.Name)
                spamChat("Đang nhặt rương!")
                
                local item = ""
                if math.random(1, 100) > 95 then
                    item = (game.PlaceId == 2753915549 and "Fist of Darkness" or "Chén Thánh")
                end
                checkChestItem(item)
                if stopCollecting then return end
                task.wait(0.3)
            end
        end
        task.wait(1)
    end
end
-- Biến để đếm số lượng rương đã nhặt
local chestsCollected = 0

-- Lấy nhân vật của người chơi
local function getCharacter()
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    return LocalPlayer.Character
end

-- Bật/tắt xuyên vật cản
local function toggleNoclip(state)
    for _, part in pairs(getCharacter():GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

-- Lấy danh sách rương trong game
local function getChests()
    local chests = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name:find("Chest") then
            table.insert(chests, obj)
        end
    end
    table.sort(chests, function(a, b)
        local root = getCharacter().HumanoidRootPart
        return (root.Position - a.Position).Magnitude < (root.Position - b.Position).Magnitude
    end)
    return chests
end

-- Xác định nhóm rương trên cùng một đảo
local function groupChestsByIsland(chests)
    local islands = {}
    
    for _, chest in ipairs(chests) do
        local foundIsland = false
        for _, island in ipairs(islands) do
            if (island[1].Position - chest.Position).Magnitude <= IslandDistanceThreshold then
                table.insert(island, chest)
                foundIsland = true
                break
            end
        end
        if not foundIsland then
            table.insert(islands, { chest })
        end
    end
    
    return islands
end

-- Bay đến vị trí rương
local function flyToTarget(targetCFrame)
    toggleNoclip(true)
    local root = getCharacter().HumanoidRootPart
    while (root.Position - targetCFrame.Position).Magnitude > 3 do
        local direction = (targetCFrame.Position - root.Position).unit
        root.CFrame = root.CFrame + direction * (MaxSpeed * RunService.Heartbeat:Wait())
    end
    toggleNoclip(false)
end

-- Dịch chuyển nếu rương quá xa
local function teleportToChest(targetChest)
    if (getCharacter().HumanoidRootPart.Position - targetChest.Position).Magnitude > ChestDetectionDistance then
        LocalPlayer.Character:BreakJoints() -- Reset nhân vật
        task.wait(3)
        getCharacter().HumanoidRootPart.CFrame = targetChest.CFrame
    else
        flyToTarget(targetChest.CFrame)
    end
end

-- Chức năng đổi server
local function hopServer()
    task.wait(3)
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    for _, server in pairs(servers.data) do
        if server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            print("Đã đổi server!")
            return
        end
    end
end

-- Nhặt rương trên từng đảo
local function collectChestsOnIsland(islandChests)
    for _, chest in ipairs(islandChests) do
        teleportToChest(chest)
        chestsCollected = chestsCollected + 1
        print("Đã nhặt rương: " .. chestsCollected)
        task.wait(0.3)

        if chestsCollected >= ChestLimit then
            hopServer()
            chestsCollected = 0
            return
        end
    end
end

-- Nhặt rương trên tất cả các đảo
local function collectAllChests()
    while true do
        local chests = getChests()
        if #chests == 0 then
            hopServer()
            return
        end
        
        local islands = groupChestsByIsland(chests)
        for _, islandChests in ipairs(islands) do
            collectChestsOnIsland(islandChests)
        end
        
        hopServer()
    end
end

-- Kiểm tra và nhặt rương
local function collectChests()
    while true do
        local chests = getChests()
        if #chests > 0 then
            for _, chest in ipairs(chests) do
                teleportToChest(chest)
                chestsCollected = chestsCollected + 1  -- Tăng số lượng rương đã nhặt
                print("Đã nhặt rương: " .. chestsCollected)
                task.wait(0,6) -- Delay ngắn khi nhặt xong rương

                -- Nếu đã nhặt đủ 165 cái rương, tự động đổi server
                if chestsCollected >= ChestLimit then
                    hopServer()
                    chestsCollected = 0  -- Reset số lượng rương sau khi đổi server
                    return  -- Dừng lại và không tiếp tục nhặt rương sau khi đổi server
                end
            end
        else
            -- Nếu không còn rương, đổi server
            hopServer()
            return
        end
        task.wait(1)
    end
end

-- Chức năng spam chat
task.spawn(function()
    while true do
        game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents").SayMessageRequest:FireServer("Tuấn Anh IOS Quá Đẹp Zai EZ", "All")
        task.wait(SpamChatDelay)  -- Chờ trước khi spam chat tiếp
    end
end)

-- Bắt đầu nhặt rương ngay khi bật script
collectChests()
