-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local AvatarDataStore = DataStoreService:GetDataStore("Passione")

local spawnEvent = Instance.new("RemoteEvent")
spawnEvent.Name = "RequestSpawn"
spawnEvent.Parent = ReplicatedStorage

local submitEvent = Instance.new("RemoteEvent")
submitEvent.Name = "SubmitCharacter"
submitEvent.Parent = ReplicatedStorage

local rerollEvent = Instance.new("RemoteEvent")
rerollEvent.Name = "RerollAppearance"
rerollEvent.Parent = ReplicatedStorage

local barberEvent = Instance.new("RemoteEvent")
barberEvent.Name = "BarberEvent"
barberEvent.Parent = ReplicatedStorage

local inventoryEvent = Instance.new("RemoteEvent")
inventoryEvent.Name = "InventoryEvent"
inventoryEvent.Parent = ReplicatedStorage

local equipEvent = Instance.new("RemoteEvent")
equipEvent.Name = "EquipEvent"
equipEvent.Parent = ReplicatedStorage

local weaponActionEvent = Instance.new("RemoteEvent")
weaponActionEvent.Name = "WeaponActionEvent"
weaponActionEvent.Parent = ReplicatedStorage

local damageIndicatorEvent = Instance.new("RemoteEvent")
damageIndicatorEvent.Name = "DamageIndicatorEvent"
damageIndicatorEvent.Parent = ReplicatedStorage

local renderBulletEvent = Instance.new("RemoteEvent")
renderBulletEvent.Name = "RenderBulletEvent"
renderBulletEvent.Parent = ReplicatedStorage

local initialInventory = HttpService:JSONEncode({
	Hotbar = {GameData.Items["Smith & Wesson .38"].Name .. "_6", "", "", "", ""},
	Stored = {"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""}
})

local Pools = {
	Masc = {
		FirstNames = {
			"James", "John", "Robert", "Michael", "William", "David", "Richard", "Joseph", "Thomas", "Charles", 
			"Christopher", "Daniel", "Matthew", "Anthony", "Mark", "Donald", "Steven", "Paul", "Andrew", "Joshua", 
			"Kenneth", "Kevin", "Brian", "George", "Timothy", "Ronald", "Edward", "Jason", "Jeffrey", "Ryan", 
			"Jacob", "Gary", "Nicholas", "Eric", "Jonathan", "Stephen", "Larry", "Justin", "Scott", "Brandon", 
			"Benjamin", "Samuel", "Gregory", "Alexander", "Frank", "Patrick", "Raymond", "Jack", "Dennis", "Jerry", 
			"Tyler", "Aaron", "Jose", "Adam", "Henry", "Nathan", "Douglas", "Zachary", "Peter", "Kyle", 
			"Walter", "Ethan", "Jeremy", "Christian", "Keith", "Roger", "Terry", "Gerald", "Harold", "Sean", 
			"Austin", "Carl", "Arthur", "Lawrence", "Dylan", "Jesse", "Victor", "Bryan", "Joe", "Noah", "Logan"
		},
		HairIDs = {
			112604007003366, 98528599025378, 80283058937678, 15563758601, 75487563047720, 
			18850865882, 123548189811001, 92061692441841, 75002416629319, 129748819870954, 
			95174346454397, 88539590756497, 139707451231957, 124120228964435, 85073098049802, 
			4773873546, 85552002879927, 73058918882985, 92206421183250, 101006327430632
		},
		Factions = {
			STREETS = {
				ShirtIDs = {6475610218, 11373066002, 6475609454, 6745531820, 10516913453, 2454118359, 113836598447031, 6140709264},
				PantsIDs = {8639706123, 106503910916588, 6363314073, 2231211984}
			},
			MAFIA = {
				ShirtIDs = {6430373850, 87318354793884, 6430378289, 6430388466, 17705703606, 82768729660708},
				PantsIDs = {18845411653}
			},
			POLICE = {
				ShirtIDs = {14864023926, 124432271572433},
				PantsIDs = {104449794109636}
			}
		},
		FaceIDs = {0}
	},
	Fem = {
		FirstNames = {
			"Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan", "Jessica", "Sarah", "Karen", 
			"Lisa", "Nancy", "Betty", "Margaret", "Sandra", "Ashley", "Kimberly", "Emily", "Donna", "Michelle", 
			"Carol", "Amanda", "Dorothy", "Melissa", "Deborah", "Stephanie", "Rebecca", "Sharon", "Laura", "Cynthia", 
			"Kathleen", "Amy", "Angela", "Shirley", "Anna", "Brenda", "Pamela", "Emma", "Nicole", "Helen", 
			"Samantha", "Katherine", "Christine", "Debra", "Rachel", "Carolyn", "Janet", "Catherine", "Maria", "Heather", 
			"Diane", "Ruth", "Julie", "Olivia", "Joyce", "Virginia", "Victoria", "Kelly", "Lauren", "Christina", 
			"Joan", "Evelyn", "Judith", "Megan", "Cheryl", "Andrea", "Hannah", "Martha", "Jacqueline", "Frances", 
			"Gloria", "Ann", "Teresa", "Kathryn", "Sara", "Janice", "Jean", "Alice", "Madison", "Doris", "Abigail", "Julia"
		},
		HairIDs = {
			132239357944331, 16989887978, 17856090938, 13515175239, 17333280320, 13473653900,
			124975286882269, 17583698245, 16317764121, 17583592654, 15848868806, 115301530609250,
			11417078736, 102439036876876, 16138295463, 17235366475, 16138301962, 74442396896368,
			104164430679537, 131060997095972, 15069719768, 129458465295140, 17832723362, 138964634412256
		},
		Factions = {
			STREETS = {
				ShirtIDs = {6475610218, 72887864504813, 12333099286, 2454118359, 16204229076},
				PantsIDs = {7976640793, 6363314073, 8639706123}
			},
			MAFIA = {
				ShirtIDs = {6430373850, 87318354793884, 6430378289},
				PantsIDs = {18845411653}
			},
			POLICE = {
				ShirtIDs = {14864023926, 124432271572433},
				PantsIDs = {104449794109636}
			}
		},
		FaceIDs = {0}
	}
}

local LastNames = {
	"Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Wilson", "Anderson", "Thomas", 
	"Taylor", "Moore", "Jackson", "Martin", "Lee", "Thompson", "White", "Harris", "Clark", "Lewis", 
	"Robinson", "Walker", "Young", "Allen", "King", "Wright", "Scott", "Hill", "Green", "Adams", 
	"Nelson", "Baker", "Hall", "Campbell", "Mitchell", "Carter", "Roberts", "Phillips", "Evans", "Turner", 
	"Parker", "Edwards", "Collins", "Stewart", "Morris", "Murphy", "Cook", "Rogers", "Morgan", "Cooper", 
	"Peterson", "Bailey", "Reed", "Kelly", "Howard", "Cox", "Ward", "Richardson", "Watson", "Brooks", 
	"Wood", "James", "Bennett", "Gray", "Hughes", "Price", "Sanders", "Myers", "Long", "Ross", 
	"Foster", "Powell", "Sullivan", "Russell", "Henderson", "Coleman", "Jenkins", "Perry", "Patterson", "Washington", 
	"Butler", "Simmons", "Bryant", "Alexander", "Griffin", "Hayes", "Harrison", "Gibson", "McDonald", "Woods", 
	"Kennedy", "Tucker", "Hoffman", "Mason", "Dixon", "Hunt", "Palmer", "Holmes", "Stone", "Hawkins"
}

local SkinColors = {
	Color3.fromRGB(253, 242, 178),
	Color3.fromRGB(245, 214, 151),
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(204, 142, 105),
	Color3.fromRGB(124, 92, 70),
	Color3.fromRGB(62, 44, 35)
}

local sessionData = {}

local function bindValueSync(player, valObj)
	valObj.Changed:Connect(function(newVal)
		local data = sessionData[player.UserId]
		if data then
			data[valObj.Name] = newVal
		end
	end)
end

local function generateRandomData(gender, faction, spawnName, skinColorIndex)
	local pool = Pools[gender] or Pools.Masc
	local fac = faction or "STREETS"
	local factionPool = pool.Factions[fac] or pool.Factions.STREETS

	return {
		Gender = gender,
		Faction = fac,
		SpawnName = spawnName,
		FirstName = pool.FirstNames[math.random(1, #pool.FirstNames)],
		LastName = LastNames[math.random(1, #LastNames)],
		Hair = tostring(pool.HairIDs[math.random(1, #pool.HairIDs)]),
		Shirt = factionPool.ShirtIDs[math.random(1, #factionPool.ShirtIDs)],
		Pants = factionPool.PantsIDs[math.random(1, #factionPool.PantsIDs)],
		Face = pool.FaceIDs[math.random(1, #pool.FaceIDs)],
		SkinColorIndex = skinColorIndex or math.random(1, #SkinColors),
		HairR = math.random(0, 255),
		HairG = math.random(0, 255),
		HairB = math.random(0, 255),
		InventoryData = initialInventory,
		ClipAmmo = 6,
		ReserveAmmo = 40
	}
end

local function reconcileData(savedData)
	local freshData = generateRandomData(savedData.Gender or "Masc", savedData.Faction or "STREETS", savedData.SpawnName or "Spawn1", savedData.SkinColorIndex)
	for key, value in pairs(freshData) do
		if savedData[key] == nil then
			savedData[key] = value
		end
	end
	return savedData
end

local function applyAvatar(character, data)
	local humanoid = character:WaitForChild("Humanoid")

	local description = Instance.new("HumanoidDescription")
	description.HairAccessory = tostring(data.Hair)
	description.Shirt = data.Shirt
	description.Pants = data.Pants
	description.Face = data.Face

	local color = SkinColors[data.SkinColorIndex]
	description.HeadColor = color
	description.LeftArmColor = color
	description.RightArmColor = color
	description.LeftLegColor = color
	description.RightLegColor = color
	description.TorsoColor = color

	humanoid:ApplyDescription(description)

	local hairColor = Color3.fromRGB(data.HairR, data.HairG, data.HairB)
	for _, acc in ipairs(character:GetChildren()) do
		if acc:IsA("Accessory") then
			local handle = acc:FindFirstChild("Handle")
			if handle then
				local hairAttachment = handle:FindFirstChild("HairAttachment")
				if hairAttachment then

					for _, obj in ipairs(handle:GetChildren()) do
						if obj:IsA("SurfaceAppearance") then
							obj:Destroy()
						end
					end

					if handle:IsA("MeshPart") then
						handle.TextureID = ""
						handle.Color = hairColor
						handle.UsePartColor = true 
					else
						local mesh = handle:FindFirstChildOfClass("SpecialMesh")
						if mesh then
							mesh.TextureId = ""
						end
						handle.Color = hairColor
					end
				end
			end
		end
	end
end

local function createHitbox(character)
	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	local head = character:WaitForChild("Head", 5)
	if not rootPart or not head then return end

	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Size = Vector3.new(4, 4.5, 2.5) 
	hitbox.BrickColor = BrickColor.new("Really red")
	hitbox.Material = Enum.Material.Neon
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Massless = true
	hitbox.CFrame = rootPart.CFrame * CFrame.new(0, -0.75, 0)
	hitbox.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = hitbox
	weld.Parent = hitbox

	local headHitbox = Instance.new("Part")
	headHitbox.Name = "HeadHitbox"
	headHitbox.Size = Vector3.new(2, 2, 2)
	headHitbox.BrickColor = BrickColor.new("New Yeller")
	headHitbox.Material = Enum.Material.Neon
	headHitbox.Transparency = 1
	headHitbox.CanCollide = false
	headHitbox.Massless = true
	headHitbox.CFrame = head.CFrame
	headHitbox.Parent = character

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = head
	headWeld.Part1 = headHitbox
	headWeld.Parent = headHitbox
end

local function teleportToSpawn(character, factionName, spawnName)
	local spawnsFolder = workspace:FindFirstChild("Spawns")
	if spawnsFolder then
		local factionFolder = spawnsFolder:FindFirstChild(factionName)
		if factionFolder then
			local targetSpawn = factionFolder:FindFirstChild(spawnName)
			if targetSpawn and targetSpawn:IsA("BasePart") and character:FindFirstChild("HumanoidRootPart") then
				character.HumanoidRootPart.CFrame = targetSpawn.CFrame + Vector3.new(0, 5, 0)
			end
		end
	end
end

spawnEvent.OnServerEvent:Connect(function(player)
	local data = sessionData[player.UserId]
	if data and data.Faction and data.SpawnName and player.Character then
		teleportToSpawn(player.Character, data.Faction, data.SpawnName)
	end
end)

submitEvent.OnServerEvent:Connect(function(player, gender, faction, spawnName, skinColorIndex)
	if type(gender) ~= "string" or type(faction) ~= "string" or type(spawnName) ~= "string" or type(skinColorIndex) ~= "number" then return end

	local newData = generateRandomData(gender, faction, spawnName, skinColorIndex)
	sessionData[player.UserId] = newData

	local playerFolder = player:FindFirstChild("AvatarData")
	if playerFolder then
		local isNewTag = playerFolder:FindFirstChild("IsNewPlayer")
		if isNewTag then isNewTag:Destroy() end

		for key, value in pairs(newData) do
			local valObj = playerFolder:FindFirstChild(key)
			if not valObj then
				valObj = type(value) == "number" and Instance.new("NumberValue") or Instance.new("StringValue")
				valObj.Name = key
				valObj.Parent = playerFolder
				bindValueSync(player, valObj)
			end
			valObj.Value = value
		end
	end

	if player.Character then
		applyAvatar(player.Character, newData)
		teleportToSpawn(player.Character, faction, spawnName)
	end
end)

rerollEvent.OnServerEvent:Connect(function(player)
	if not RunService:IsStudio() then return end
	local oldData = sessionData[player.UserId]
	if not oldData then return end
	local newData = generateRandomData(oldData.Gender, oldData.Faction, oldData.SpawnName, oldData.SkinColorIndex)
	sessionData[player.UserId] = newData
	local playerFolder = player:FindFirstChild("AvatarData")
	if playerFolder then
		for key, value in pairs(newData) do
			local valObj = playerFolder:FindFirstChild(key)
			if valObj then valObj.Value = value end
		end
	end
	if player.Character then applyAvatar(player.Character, newData) end
end)

barberEvent.OnServerEvent:Connect(function(player, action, payload)
	local data = sessionData[player.UserId]
	if not data then return end

	if action == "Custom" then
		data.Hair = tostring(payload)
	elseif action == "Default" then
		local success, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(player.UserId)
		end)
		if success and desc then
			local hairs = desc.HairAccessory
			if hairs == "" then
				for _, acc in ipairs(desc:GetAccessories(true)) do
					if acc.AccessoryType == Enum.AccessoryType.Hair then
						hairs = hairs .. (hairs == "" and "" or ",") .. tostring(acc.AssetId)
					end
				end
			end
			data.Hair = hairs
		end
	elseif action == "RandomColor" then
		data.HairR = math.random(0, 255)
		data.HairG = math.random(0, 255)
		data.HairB = math.random(0, 255)
	end

	local playerFolder = player:FindFirstChild("AvatarData")
	if playerFolder then
		local hVal = playerFolder:FindFirstChild("Hair")
		if hVal then hVal.Value = data.Hair end
		local rVal = playerFolder:FindFirstChild("HairR")
		if rVal then rVal.Value = data.HairR end
		local gVal = playerFolder:FindFirstChild("HairG")
		if gVal then gVal.Value = data.HairG end
		local bVal = playerFolder:FindFirstChild("HairB")
		if bVal then bVal.Value = data.HairB end
	end

	if player.Character then
		applyAvatar(player.Character, data)
	end
end)

inventoryEvent.OnServerEvent:Connect(function(player, invData)
	if type(invData) == "string" then
		local data = sessionData[player.UserId]
		if data then
			data.InventoryData = invData
			local playerFolder = player:FindFirstChild("AvatarData")
			if playerFolder then
				local invVal = playerFolder:FindFirstChild("InventoryData")
				if invVal then
					invVal.Value = invData
				end
			end
		end
	end
end)

equipEvent.OnServerEvent:Connect(function(player, itemName)
	local character = player.Character
	if not character then return end

	local oldEquip = character:FindFirstChild("EquippedItem")
	if oldEquip then
		oldEquip:Destroy()
	end

	if type(itemName) ~= "string" or itemName == "" then return end

	local itemData = GameData.Items[itemName]
	if itemData and itemData.Model and itemData.Model ~= "" then
		local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
		if itemsFolder then
			local modelTemplate = itemsFolder:FindFirstChild(itemData.Model)
			if modelTemplate then
				local newModel = modelTemplate:Clone()
				newModel.Name = "EquippedItem"

				local rightArm = character:FindFirstChild("Right Arm")
				local primaryPart = newModel.PrimaryPart or newModel:FindFirstChildWhichIsA("BasePart")

				if rightArm and primaryPart then
					newModel.Parent = character

					for _, desc in ipairs(newModel:GetDescendants()) do
						if desc:IsA("BasePart") and desc ~= primaryPart then
							desc.Anchored = false
							local internalWeld = Instance.new("WeldConstraint")
							internalWeld.Part0 = primaryPart
							internalWeld.Part1 = desc
							internalWeld.Parent = desc
						end
					end
					primaryPart.Anchored = false

					local equipWeld = Instance.new("Weld")
					equipWeld.Name = "EquipWeld"
					equipWeld.Part0 = rightArm
					equipWeld.Part1 = primaryPart

					equipWeld.C0 = CFrame.new(0, -1, 0)

					local grip = primaryPart:FindFirstChild("Grip")
					if grip and grip:IsA("Attachment") then
						equipWeld.C1 = grip.CFrame
					end

					equipWeld.Parent = primaryPart
				end
			end
		end
	end
end)

local function initializeItemSpawns()
	local spawnpoints = workspace:FindFirstChild("Spawnpoints")
	if not spawnpoints then return end

	local spawnablePool = {}
	local totalWeight = 0

	for itemName, data in pairs(GameData.Items) do
		if data.Spawnable and data.Rarity then
			table.insert(spawnablePool, {Name = itemName, Weight = data.Rarity, Data = data})
			totalWeight = totalWeight + data.Rarity
		end
	end

	if totalWeight <= 0 then return end

	for _, spawnPart in ipairs(spawnpoints:GetChildren()) do
		if spawnPart:IsA("BasePart") and string.lower(spawnPart.Name) == "item_spawn" then
			spawnPart.Transparency = 1
			spawnPart.CanCollide = false

			if math.random() <= 0.5 then
				local roll = math.random(1, totalWeight)
				local currentWeight = 0
				local selectedItem = nil

				for _, item in ipairs(spawnablePool) do
					currentWeight = currentWeight + item.Weight
					if roll <= currentWeight then
						selectedItem = item
						break
					end
				end

				if selectedItem then
					local itemModel
					local itemsFolder = ReplicatedStorage:FindFirstChild("Items")

					if itemsFolder and selectedItem.Data.Model and selectedItem.Data.Model ~= "" then
						local template = itemsFolder:FindFirstChild(selectedItem.Data.Model)
						if template then
							itemModel = template:Clone()
						end
					end

					if not itemModel then
						itemModel = Instance.new("Part")
						itemModel.Size = Vector3.new(1, 1, 1)
						itemModel.BrickColor = BrickColor.new("Bright green")
						itemModel.Material = Enum.Material.SmoothPlastic
					end

					itemModel.Name = "Dropped_" .. selectedItem.Name

					local promptPart = itemModel
					if itemModel:IsA("Model") then
						promptPart = itemModel.PrimaryPart or itemModel:FindFirstChildWhichIsA("BasePart")
						for _, desc in ipairs(itemModel:GetDescendants()) do
							if desc:IsA("BasePart") then
								desc.Anchored = true
								desc.CanCollide = true
							end
						end
						if promptPart then
							itemModel:PivotTo(spawnPart.CFrame)
						else
							itemModel:PivotTo(spawnPart.CFrame)
						end
					else
						itemModel.Anchored = true
						itemModel.CanCollide = true
						itemModel.CFrame = spawnPart.CFrame
					end

					if promptPart then
						local prompt = Instance.new("ProximityPrompt")
						prompt.ActionText = "Pick Up"
						prompt.ObjectText = selectedItem.Name
						prompt.RequiresLineOfSight = false
						prompt.HoldDuration = 0.5
						prompt.Parent = promptPart

						prompt.Triggered:Connect(function(plr)
							local avatarData = plr:FindFirstChild("AvatarData")
							local invVal = avatarData and avatarData:FindFirstChild("InventoryData")
							if invVal then
								local success, inv = pcall(function() return HttpService:JSONDecode(invVal.Value) end)
								if success and inv then
									local itemNameWithAmmo = selectedItem.Name
									if selectedItem.Data.MaxClip then
										itemNameWithAmmo = selectedItem.Name .. "_" .. selectedItem.Data.MaxClip
									end

									local added = false
									for i = 1, 5 do
										if inv.Hotbar[i] == "" then
											inv.Hotbar[i] = itemNameWithAmmo
											added = true
											break
										end
									end
									if not added then
										for i = 1, 20 do
											if inv.Stored[i] == "" then
												inv.Stored[i] = itemNameWithAmmo
												added = true
												break
											end
										end
									end

									if added then
										invVal.Value = HttpService:JSONEncode(inv)
										itemModel:Destroy()
									end
								end
							end
						end)
					end

					itemModel.Parent = workspace
				end
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local isNew = false
	local savedData = nil
	if RunService:IsStudio() then isNew = true
	else
		local success, result = pcall(function() return AvatarDataStore:GetAsync(player.UserId) end)
		if success and result then savedData = reconcileData(result) else isNew = true end
	end
	local playerFolder = Instance.new("Folder")
	playerFolder.Name = "AvatarData"
	if isNew then
		local newTag = Instance.new("BoolValue")
		newTag.Name = "IsNewPlayer"
		newTag.Value = true
		newTag.Parent = playerFolder
		sessionData[player.UserId] = {IsNew = true}
	else
		sessionData[player.UserId] = savedData
		for key, value in pairs(savedData) do
			local valObj = type(value) == "number" and Instance.new("NumberValue") or Instance.new("StringValue")
			valObj.Name = key
			valObj.Value = value
			valObj.Parent = playerFolder
			bindValueSync(player, valObj)
		end
	end
	playerFolder.Parent = player

	player.CharacterAdded:Connect(function(character)
		local data = sessionData[player.UserId]
		if data then
			task.delay(0.1, function()
				if data.Gender then applyAvatar(character, data) end
				createHitbox(character)
				if data.Faction and data.SpawnName then
					teleportToSpawn(character, data.Faction, data.SpawnName)
				end
			end)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local data = sessionData[player.UserId]
	if data and not data.IsNew and not RunService:IsStudio() then
		pcall(function() AvatarDataStore:SetAsync(player.UserId, data) end)
	end
	sessionData[player.UserId] = nil
end)

initializeItemSpawns()

game:BindToClose(function()
	if RunService:IsStudio() then return end
	for _, player in ipairs(Players:GetPlayers()) do
		local data = sessionData[player.UserId]
		if data and not data.IsNew then pcall(function() AvatarDataStore:SetAsync(player.UserId, data) end) end
	end
end)