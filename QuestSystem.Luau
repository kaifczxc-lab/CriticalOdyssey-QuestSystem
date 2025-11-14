local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestConfig = require(ReplicatedStorage.QuestSystem.QuestConfig)
local QuestRemote = ReplicatedStorage.Remotes.QuestRemote

local playerQuests = {}
local questCooldowns = {} --cooldown in the ticks

--give reward function
local function giveRewards(player, quest)
	local rewards = quest.Rewards
	if not rewards then return false end

	local success = true

	-- Give Items
	if rewards.Items then
		for _, itemName in ipairs(rewards.Items) do
			local item = ReplicatedStorage.Items.ActiveItems:FindFirstChild(itemName)
				or ReplicatedStorage.Items.PassiveItems:FindFirstChild(itemName)
				or ReplicatedStorage.Items.Materials:FindFirstChild(itemName)
			if item then
				local newItem = Instance.new("IntValue")
				newItem.Name = itemName
				newItem.Parent = player.PlayerData.Inventory
				print("Reward item:", itemName, "→", player.Name)
			else
				warn("Item not found:", itemName)
				success = false
			end
		end
	end

	-- Give Gold
	if rewards.Gold and player.leaderstats:FindFirstChild("Gold") then
		player.leaderstats.Gold.Value = player.leaderstats.Gold.Value + rewards.Gold
		print("Reward gold:", rewards.Gold, "to", player.Name)
	end

	-- Give Reputation
	if rewards.Reputation and player.leaderstats:FindFirstChild("Reputation") then
		player.leaderstats.Reputation.Value = player.leaderstats.Reputation.Value + rewards.Reputation
		print("Reward rep:", rewards.Reputation, "to", player.Name)
	end

	-- Give Experience
	if rewards.Experience and player.PlayerData:FindFirstChild("Exp") then
		player.PlayerData.Exp.Value = player.PlayerData.Exp.Value + rewards.Experience
		print("Reward exp:", rewards.Experience, "to", player.Name)
	end

	return success
end

local function checkQuestProgress(player, enemyName)
	if not playerQuests[player.UserId] then return end

	for qId, qData in pairs(playerQuests[player.UserId]) do
		if qData.Active then
			local quest = QuestConfig:GetQuest(qId)
			if quest and (quest.QuestType == "Kill" or quest.QuestType == "Gathering") then --quest type
				for targetIndex, target in ipairs(quest.Targets) do
					if target.Name == enemyName then


						if not qData.TargetProgress then

							qData.TargetProgress = {} --mobs progress
						end
						if not qData.TargetProgress[targetIndex] then
							qData.TargetProgress[targetIndex] = 0
						end

						qData.TargetProgress[targetIndex] = qData.TargetProgress[targetIndex] + 1

						local totalProgress = 0
						local totalTarget = 0
						for i, t in ipairs(quest.Targets) do
							totalProgress = totalProgress + (qData.TargetProgress[i] or 0)
							totalTarget = totalTarget + t.Amount
						end

						QuestRemote:FireClient(player, "QuestProgress", qId, totalProgress, totalTarget, quest.Targets, qData.TargetProgress)

						print(player.Name, qId, ":", totalProgress .. "/" .. totalTarget)

						if totalProgress >= totalTarget then --if progress more that targets then active is not true
							qData.Active = false
							if quest.QuestType == "Gathering" and quest.Requirements and quest.Requirements.Items then
								for _, reqItem in ipairs(quest.Requirements.Items) do
									if reqItem.Consume then --consuming items
										local itemName = reqItem.Name
										local reqAmount = reqItem.Amount or 1 --get amount or 1
										local inventory = player.PlayerData.Inventory --get player inventory
										local deleted = 0
										for _, item in ipairs(inventory:GetChildren()) do
											if item.Name == itemName and deleted < reqAmount then
												item:Destroy()
												deleted = deleted + 1
												print("Consumed on complete:", itemName, "from", player.Name)
											end
										end
										game.ReplicatedStorage.Remotes.ItemSetup:FireClient(player, "ItemValueUpdate", nil, 0)
									end
								end
							end
							if giveRewards(player, quest) then
								if quest.Cooldown then
									if not questCooldowns[player.UserId] then
										questCooldowns[player.UserId] = {}
									end
									questCooldowns[player.UserId][qId] = tick()
								end
								QuestRemote:FireClient(player, "QuestCompleted", qId)
								print("Done", player.Name, "completed:", qId)
							end
						end
					end
				end
			end
		end
	end
end

QuestRemote.OnServerEvent:Connect(function(player, action, questId, data) --get all abt quests
	if action == "StartQuest" then
		local quest = QuestConfig:GetQuest(questId)
		if not quest then
			warn("Quest not found:", questId)
			return
		end

		if not player:FindFirstChild("leaderstats") or not player.leaderstats:FindFirstChild("CombatStyle") then
			warn("Leaderstats not found for", player.Name)
			return
		end

		if quest.RequiredClass then
			local currentClass = player.leaderstats.CombatStyle.Value
			if currentClass ~= quest.RequiredClass then
				QuestRemote:FireClient(player, "QuestError", "Wrong class!")
				return
			end
		end
		--cooldown function
		if quest.Cooldown then
			if not questCooldowns[player.UserId] then
				questCooldowns[player.UserId] = {}
			end

			local lastCompleted = questCooldowns[player.UserId][questId]
			if lastCompleted then
				local timeElapsed = tick() - lastCompleted
				local timeRemaining = quest.Cooldown - timeElapsed

				if timeRemaining > 0 then
					local hours = math.floor(timeRemaining / 3600)
					local minutes = math.floor((timeRemaining % 3600) / 60)
					local seconds = math.floor(timeRemaining % 60)
					local timeText = ""
					if hours > 0 then
						timeText = hours .. "h " .. minutes .. "m"
					elseif minutes > 0 then
						timeText = minutes .. "m " .. seconds .. "s"
					else
						timeText = seconds .. "s"
					end
					QuestRemote:FireClient(player, "QuestError", "Cooldown: " .. timeText)
					return
				end
			end
		end
		
		if quest.Requirements then
			if quest.Requirements.Gold then
				local gold = player.leaderstats:FindFirstChild("Gold")
				if not gold or gold.Value < quest.Requirements.Gold then
					QuestRemote:FireClient(player, "QuestError", "Need " .. quest.Requirements.Gold .. " Gold")
					return
				end
			end

			if quest.Requirements.Items then
				local itemsToConsume = {}
				local inventory = player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("Inventory")

				if not inventory then
					QuestRemote:FireClient(player, "QuestError", "Inventory dont have in this universe")
					return
				end
			
				for _, reqItem in ipairs(quest.Requirements.Items) do
					local itemName = reqItem.Name
					local reqAmount = reqItem.Amount or 1
					local shouldConsume = reqItem.Consume or false
					local foundItems = {}
					for _, item in ipairs(inventory:GetChildren()) do
						if item.Name == itemName then
							table.insert(foundItems, item)
						end
					end

					local count = #foundItems
					if count < reqAmount then
						local consumeText = shouldConsume and " (will be consumed)" or ""
						QuestRemote:FireClient(player, "QuestError","Need "..reqAmount.."x"..itemName.." (have "..count..")"..consumeText)
						return
					end

					if shouldConsume then
						for i = 1, reqAmount do
							table.insert(itemsToConsume, foundItems[i])
						end
					end
				end

				if quest.Requirements.Gold and player.leaderstats:FindFirstChild("Gold") then
					player.leaderstats.Gold.Value = player.leaderstats.Gold.Value - quest.Requirements.Gold
					print("Spent on quest:", quest.Requirements.Gold, "gold from", player.Name)
				end

				if #itemsToConsume > 0 then
					for _, item in ipairs(itemsToConsume) do
						print("Consumed:", item.Name, "from", player.Name)
						item:Destroy()
					end
					task.wait(0.1)
					game.ReplicatedStorage.Remotes.ItemSetup:FireClient(player, "ItemValueUpdate", nil, 0)
					QuestRemote:FireClient(player, "ItemsConsumed", #itemsToConsume)
				end
			end

			if quest.Requirements.MinLevel then
				local level = player.leaderstats:FindFirstChild("Level")
				if not level or level.Value < quest.Requirements.MinLevel then
					QuestRemote:FireClient(player, "QuestError", "Need level " .. quest.Requirements.MinLevel)
					return
				end
			end

			if quest.Requirements.MinDamage then
				local damage = player.leaderstats:FindFirstChild("Damage")
				if not damage or damage.Value < quest.Requirements.MinDamage then
					QuestRemote:FireClient(player, "QuestError", "Need " .. quest.Requirements.MinDamage .. " Damage stat")
					return
				end
			end
		end

		if not playerQuests[player.UserId] then
			playerQuests[player.UserId] = {}
		end

		if playerQuests[player.UserId][questId] and playerQuests[player.UserId][questId].Active then
			QuestRemote:FireClient(player, "QuestError", "Quest already active")
			return
		end

		local totalTarget = 0
		for _, target in ipairs(quest.Targets) do
			totalTarget = totalTarget + target.Amount
		end


		local initialProgress = {}
		for i = 1, #quest.Targets do
			table.insert(initialProgress, 0)
		end

		playerQuests[player.UserId][questId] = {
			Progress = 0,
			Target = totalTarget,
			Active = true,
			TargetProgress = initialProgress
		}

		QuestRemote:FireClient(player, "QuestStarted", questId, quest)
		print(player.Name, "started quest:", questId)

	elseif action == "CancelQuest" then
		if playerQuests[player.UserId] then
			playerQuests[player.UserId] = {}
			print(player.Name, "Canceled All Quests")
		end
		QuestRemote:FireClient(player, "CancelAllQuests")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playerQuests[player.UserId] = nil
	questCooldowns[player.UserId] = nil
end)

_G.QuestSystem_OnEnemyDefeated = function(enemyName, playerDamageFolder)
	if not playerDamageFolder then return end

	local damageData = {}
	for _, damageValue in pairs(playerDamageFolder:GetChildren()) do
		if damageValue:IsA("NumberValue") then
			table.insert(damageData, {
				PlayerName = damageValue.Name,
				Damage = damageValue.Value
			})
		end
	end

	table.sort(damageData, function(a, b)
		return a.Damage > b.Damage
	end)

	for _, data in ipairs(damageData) do
		local player = Players:FindFirstChild(data.PlayerName)
		if player then
			checkQuestProgress(player, enemyName)
		end
	end
end

print("QuestServer Script is loaded")
