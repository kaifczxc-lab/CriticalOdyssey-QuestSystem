--[[
    Quest Tracker UI (Client)
    -------------------------
    This script creates a simple quest tracker UI using code.
    If you prefer to use your own GUI from StarterGui, you can replace
    the createQuestGUI() function and use your layout instead.

    Requirements for custom UI:
      • A container Frame to hold quest entries
      • Each quest entry should contain:
            - Title label named "Title"
            - Frame named "Targets" with target rows named "Target1", "Target2", ...

    The logic below will still work as long as the naming matches.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local QuestRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("QuestRemote")

local activeQuests = {}
local questFrame


-- Creates UI container if player does not have their own GUI
local function createQuestGUI()
    -- Default code-generated UI. Replace this with your own StarterGui UI if desired.
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "QuestTracker"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 300, 0, 0)
    container.Position = UDim2.new(1, -320, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = screenGui

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = container

    return container
end


-- Builds the display for a single quest
local function createQuestDisplay(questId, questData)
    local targetLines = #questData.Targets
    local height = 60 + (targetLines * 25)

    local frame = Instance.new("Frame")
    frame.Name = questId
    frame.Size = UDim2.new(1, 0, 0, height)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 25)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = questData.QuestName
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 18
    title.Font = Enum.Font.FredokaOne
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local targetsContainer = Instance.new("Frame")
    targetsContainer.Name = "Targets"
    targetsContainer.Size = UDim2.new(1, -20, 1, -35)
    targetsContainer.Position = UDim2.new(0, 10, 0, 30)
    targetsContainer.BackgroundTransparency = 1
    targetsContainer.Parent = frame

    local targetLayout = Instance.new("UIListLayout")
    targetLayout.SortOrder = Enum.SortOrder.LayoutOrder
    targetLayout.Padding = UDim.new(0, 5)
    targetLayout.Parent = targetsContainer

    -- Create target rows
    for i, target in ipairs(questData.Targets) do
        local label = Instance.new("TextLabel")
        label.Name = "Target" .. i
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = "Kill 0/" .. target.Amount .. " " .. target.Name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.FredokaOne
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = targetsContainer
    end

    return frame
end


-- Handles updates from the server
QuestRemote.OnClientEvent:Connect(function(action, questId, data, _, targets, targetProgress)
    
    -- Player starts a new quest
    if action == "QuestStarted" then
        if not questFrame then
            questFrame = createQuestGUI()
        end

        activeQuests[questId] = data
        local display = createQuestDisplay(questId, data)
        display.Parent = questFrame

        questFrame.Size = UDim2.new(0, 300, 0, questFrame.UIListLayout.AbsoluteContentSize.Y)


    -- Progress update for a quest
    elseif action == "QuestProgress" then
        if questFrame then
            local display = questFrame:FindFirstChild(questId)
            if display and targets and targetProgress then
                local targetContainer = display:FindFirstChild("Targets")
                if targetContainer then
                    for i, target in ipairs(targets) do
                        local row = targetContainer:FindFirstChild("Target" .. i)
                        if row then
                            local value = targetProgress[i] or 0
                            row.Text = "Kill " .. value .. "/" .. target.Amount .. " " .. target.Name

                            if value >= target.Amount then
                                row.TextColor3 = Color3.fromRGB(100, 255, 100)
                            end
                        end
                    end
                end
            end
        end


    -- Quest completed
    elseif action == "QuestCompleted" then
        if questFrame then
            local display = questFrame:FindFirstChild(questId)
            if display then
                display.Title.Text = "COMPLETED!"
                display.Title.TextColor3 = Color3.fromRGB(50, 255, 50)

                task.wait(2)
                display:Destroy()

                activeQuests[questId] = nil

                if #questFrame:GetChildren() <= 1 then
                    questFrame.Parent:Destroy()
                    questFrame = nil
                else
                    questFrame.Size = UDim2.new(0, 300, 0, questFrame.UIListLayout.AbsoluteContentSize.Y)
                end
            end
        end


    -- Player cancels all quests
    elseif action == "CancelAllQuests" then
        if questFrame then
            questFrame.Parent:Destroy()
            questFrame = nil
            activeQuests = {}
        end


    -- Error from server
    elseif action == "QuestError" then
        warn("Quest Error:", questId)
    end
end)
