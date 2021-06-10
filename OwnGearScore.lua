function GearScore_OnEvent(GS_Nil, GS_EventName, GS_Prefix, GS_AddonMessage, GS_Whisper, GS_Sender)
	if ( GS_EventName == "PLAYER_REGEN_ENABLED" ) then
		GS_PlayerIsInCombat = false
		return
	end

	if ( GS_EventName == "PLAYER_REGEN_DISABLED" ) then
		GS_PlayerIsInCombat = true
		return
	end

	if ( GS_EventName == "PLAYER_EQUIPMENT_CHANGED" ) then
		local MyGearScore, MyItemLevel = GearScore_GetPlayerScore()
		PersonalGearScore:SetText(MyGearScore)
		PersonalItemLevel:SetText(MyItemLevel)
		
		local Red, Blue, Green = GearScore_GetQuality(MyGearScore)
		PersonalGearScore:SetTextColor(Red, Green, Blue, 1)
		PersonalItemLevel:SetTextColor(Red, Green, Blue, 1)
	end

	if ( GS_EventName == "ADDON_LOADED" ) then
		if ( GS_Prefix == "OwnGearScore" ) then
			if not ( GS_Settings ) then
				GS_Settings = GS_DefaultSettings
			end
			for i, v in pairs(GS_DefaultSettings) do
				if not ( GS_Settings[i] ) then
					GS_Settings[i] = GS_DefaultSettings[i]
				end
			end
		end
	end
end

function GearScore_GetPlayerScore()
	local Target = "player"
	local PlayerClass, PlayerEnglishClass = UnitClass(Target)
	local GearScore = 0
	local ItemScore = 0
	local ItemCount = 0
	local LevelTotal = 0
	local ItemLink

	for i = 1, 18 do
		if ( i ~= 4 ) then
			ItemLink = GetInventoryItemLink(Target, i)
			GS_ItemLinkTable = {}
			if ( ItemLink ) then
				local _, ItemLink = GetItemInfo(ItemLink)
				if ( GS_Settings["Detail"] == 1 ) then
					GS_ItemLinkTable[i] = ItemLink
				end
				ItemScore, ItemLevel = GearScore_GetItemScore(ItemLink)
				if ( i == 16 or i == 17 ) and ( PlayerEnglishClass == "HUNTER" ) then
					ItemScore = ItemScore * 0.3164
				end
				if ( i == 18 ) and ( PlayerEnglishClass == "HUNTER" ) then
					ItemScore = ItemScore * 5.3224
				end
				GearScore = GearScore + ItemScore
				ItemCount = ItemCount + 1
				LevelTotal = LevelTotal + ItemLevel
			end
		end
	end

	if ( ItemCount == 0 ) then
		return 0, 0
	end

	if ( GearScore <= 0 ) then
		GearScore = 0
	end

	return floor(GearScore), floor(LevelTotal/ItemCount)
end

function GearScorePvPTrinketFix(ItemID, ItemLevel)
	if (ItemID == 18852) or (ItemID == 18849) or (ItemID == 18846) or (ItemID == 18834) or (ItemID == 18851) or (ItemID == 18850) or (ItemID == 29592) or 
		(ItemID == 18845) or (ItemID == 18853) or (ItemID == 18854) or (ItemID == 18858) or (ItemID == 29593) or (ItemID == 18857) or (ItemID == 18856) or 
		(ItemID == 18862) or (ItemID == 18859) or (ItemID == 18864) or (ItemID == 18863) then
		return 90
	end

	return ItemLevel
end

function GearScore_GetEnchantInfo(ItemLink, ItemEquipLoc)
	local found, _, ItemSubString = string.find(ItemLink, "^|c%x+|H(.+)|h%[.*%]")
	local ItemSubStringTable = {}
	local bonusPercent = 1
	local enchCount = 0

	for v in string.gmatch(ItemSubString, "[^:]+") do
		tinsert(ItemSubStringTable, v)
	end
	if ( ItemSubStringTable[3] == "0" ) and( GS_ItemTypes[ItemEquipLoc]["Enchantable"] ) then
		enchCount = enchCount - 1
	end

	for i = 4, 7 do
		if ( ItemSubStringTable[i] ~= "0" ) then
			enchCount = enchCount + 1
		end
	end

	bonusPercent = (floor(2 * (GS_ItemTypes[ItemEquipLoc]["SlotMOD"]) * 100 * enchCount) / 100)
	return (1 + (bonusPercent/100))
end

function GearScore_GetItemScore(ItemLink)
	local QualityScale = 1
	local GearScore = 0
	if not ( ItemLink ) then
		return 0, 0
	end

	local _, ItemLink, ItemRarity, ItemLevel, _, _, _, _, ItemEquipLoc, _ = GetItemInfo(ItemLink)
	local Table = {}
	local Scale = 2.97
	local ItemID = GetItemInfoFromHyperlink(ItemLink)
	ItemLevel = GearScorePvPTrinketFix(ItemID, ItemLevel)
	if ( ItemRarity == 5 ) then
		QualityScale = 1.3
		ItemRarity = 4
	elseif ( ItemRarity == 1 ) then
		QualityScale = 0.005
		ItemRarity = 2
	elseif ( ItemRarity == 0 ) then
		QualityScale = 0.005
		ItemRarity = 2
	end

	if ( GS_ItemTypes[ItemEquipLoc] ) then
		if ( ItemLevel > 92 ) then
			Table = GS_Formula["A"]
		else
			Table = GS_Formula["B"]
		end

		if ( ItemRarity >= 2 ) and ( ItemRarity <= 4 ) then
			local Red, Green, Blue = GearScore_GetQuality((floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * 1 * Scale)) * 16.98 )
			GearScore = floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * GS_ItemTypes[ItemEquipLoc].SlotMOD * Scale * QualityScale)
			if ( GearScore < 0 ) then
				GearScore = 0
				Red, Green, Blue = GearScore_GetQuality(1)
			end

			local percent = (GearScore_GetEnchantInfo(ItemLink, ItemEquipLoc) or 1)
			GearScore = floor(GearScore * percent )

			return GearScore, ItemLevel, GS_ItemTypes[ItemEquipLoc].ItemSlot, Red, Green, Blue, ItemEquipLoc, percent
		end
	end

	return -1, ItemLevel, 50, 1, 1, 1, ItemEquipLoc, 1
end

function GearScore_GetQuality(ItemScore)
	if ( ItemScore > 5999 ) then
		ItemScore = 5999
	end

	local Red = 0.1
	local Blue = 0.1
	local Green = 0.1
	local GS_QualityDescription = "Legendary"
	if not ( ItemScore ) then
		return 0, 0, 0, "Trash"
	end

	for i = 0, 6 do
		if ( ItemScore > i * 1000 ) and ( ItemScore <= ( ( i + 1 ) * 1000 ) ) then
			local Red = GS_Quality[( i + 1 ) * 1000].Red["A"] + (((ItemScore - GS_Quality[( i + 1 ) * 1000].Red["B"])*GS_Quality[( i + 1 ) * 1000].Red["C"])*GS_Quality[( i + 1 ) * 1000].Red["D"])
			local Blue = GS_Quality[( i + 1 ) * 1000].Green["A"] + (((ItemScore - GS_Quality[( i + 1 ) * 1000].Green["B"])*GS_Quality[( i + 1 ) * 1000].Green["C"])*GS_Quality[( i + 1 ) * 1000].Green["D"])
			local Green = GS_Quality[( i + 1 ) * 1000].Blue["A"] + (((ItemScore - GS_Quality[( i + 1 ) * 1000].Blue["B"])*GS_Quality[( i + 1 ) * 1000].Blue["C"])*GS_Quality[( i + 1 ) * 1000].Blue["D"])
			--if not ( Red ) or not ( Blue ) or not ( Green ) then return 0.1, 0.1, 0.1, nil end
			return Red, Green, Blue, GS_Quality[( i + 1 ) * 1000].Description
		end
	end

	return 255, 255, 255
end

function GearScore_HookSetItem()
	ItemName, ItemLink = GameTooltip:GetItem()
	GearScore_HookItem(ItemName, ItemLink, GameTooltip)
end

function GearScore_HookRefItem()
	ItemName, ItemLink = ItemRefTooltip:GetItem()
	GearScore_HookItem(ItemName, ItemLink, ItemRefTooltip)
end

function GearScore_HookCompareItem()
	ItemName, ItemLink = ShoppingTooltip1:GetItem()
	GearScore_HookItem(ItemName, ItemLink, ShoppingTooltip1)
end

function GearScore_HookCompareItem2()
	ItemName, ItemLink = ShoppingTooltip2:GetItem()
	GearScore_HookItem(ItemName, ItemLink, ShoppingTooltip2)
end

function GearScore_HookItem(ItemName, ItemLink, Tooltip)
	if ( GS_PlayerIsInCombat ) then
		return
	end

	local PlayerClass, PlayerEnglishClass = UnitClass("player")
	if not ( IsEquippableItem(ItemLink) ) then
		return
	end

	local ItemScore, ItemLevel, EquipLoc, Red, Green, Blue, ItemEquipLoc, enchantPercent = GearScore_GetItemScore(ItemLink)
	if ( ItemScore >= 0 ) then
		if ( GS_Settings["Item"] == 1 ) then
			if ( ItemLevel ) then
				Tooltip:AddDoubleLine("GearScore: "..ItemScore, "(iLevel "..ItemLevel..")", Red, Blue, Green, Red, Blue, Green)
				if ( PlayerEnglishClass == "HUNTER" ) then
					if ( ItemEquipLoc == "INVTYPE_RANGEDRIGHT" ) or ( ItemEquipLoc == "INVTYPE_RANGED" ) then
						Tooltip:AddLine("HunterScore: "..floor(ItemScore * 5.3224), Red, Blue, Green)
					end
					if ( ItemEquipLoc == "INVTYPE_2HWEAPON" ) or ( ItemEquipLoc == "INVTYPE_WEAPONMAINHAND" ) or ( ItemEquipLoc == "INVTYPE_WEAPONOFFHAND" ) or ( ItemEquipLoc == "INVTYPE_WEAPON" ) or ( ItemEquipLoc == "INVTYPE_HOLDABLE" ) then
						Tooltip:AddLine("HunterScore: "..floor(ItemScore * 0.3164), Red, Blue, Green)
					end
				end
			else
				Tooltip:AddLine("GearScore: "..ItemScore, Red, Blue, Green)
				if ( PlayerEnglishClass == "HUNTER" ) then
					if ( ItemEquipLoc == "INVTYPE_RANGEDRIGHT" ) or ( ItemEquipLoc == "INVTYPE_RANGED" ) then
						Tooltip:AddLine("HunterScore: "..floor(ItemScore * 5.3224), Red, Blue, Green)
					end
					if ( ItemEquipLoc == "INVTYPE_2HWEAPON" ) or ( ItemEquipLoc == "INVTYPE_WEAPONMAINHAND" ) or ( ItemEquipLoc == "INVTYPE_WEAPONOFFHAND" ) or ( ItemEquipLoc == "INVTYPE_WEAPON" ) or ( ItemEquipLoc == "INVTYPE_HOLDABLE" ) then
						Tooltip:AddLine("HunterScore: "..floor(ItemScore * 0.3164), Red, Blue, Green)
					end
				end
			end
		end
	else
		if ( ItemLevel ) then
			Tooltip:AddLine("iLevel "..ItemLevel)
		end
	end
end

function MyPaperDoll()
	if ( GS_PlayerIsInCombat ) then
		return
	end

	local MyGearScore, MyItemLevel = GearScore_GetPlayerScore()
	local Red, Blue, Green = GearScore_GetQuality(MyGearScore)
	PersonalGearScore:SetText(MyGearScore)
	PersonalGearScore:SetTextColor(Red, Green, Blue, 1)
	PersonalItemLevel:SetText(MyItemLevel)
	PersonalItemLevel:SetTextColor(Red, Green, Blue, 1)
end

function GS_MANSET(Command)
	local output
	if ( strlower(Command) == "" ) or ( strlower(Command) == "options" ) or ( strlower(Command) == "option" ) or ( strlower(Command) == "help" ) then
		for i, v in ipairs(GS_CommandList) do
			DEFAULT_CHAT_FRAME:AddMessage(v)
		end 
		for i, v in pairs(GS_Settings) do
			if (v == 1) then
				output = i..": On"
			else
				output = i..": Off"
			end
			DEFAULT_CHAT_FRAME:AddMessage(output)
		end

		return
	end

	if ( strlower(Command) == "player" ) then
		GS_Settings["Player"] = GS_ShowSwitch[GS_Settings["Player"]]
		if ( GS_Settings["Player"] == 1 ) or ( GS_Settings["Player"] == 2 ) then
			DEFAULT_CHAT_FRAME:AddMessage("Player Scores: On")
		else
			DEFAULT_CHAT_FRAME:AddMessage("Player Scores: Off")
		end
		return
	end

	if ( strlower(Command) == "item" ) then
		GS_Settings["Item"] = GS_ItemSwitch[GS_Settings["Item"]]
		if ( GS_Settings["Item"] == 1 ) or ( GS_Settings["Item"] == 3 ) then
			DEFAULT_CHAT_FRAME:AddMessage("Item Scores: On")
		else
			DEFAULT_CHAT_FRAME:AddMessage("Item Scores: Off")
		end
		return
	end

	DEFAULT_CHAT_FRAME:AddMessage("GearScore: Unknown Command. Type '/gs' for a list of options")
end

local f = CreateFrame("Frame", "GearScore", UIParent)

f:SetScript("OnEvent", GearScore_OnEvent)
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
GameTooltip:HookScript("OnTooltipSetItem", GearScore_HookSetItem)
ItemRefTooltip:HookScript("OnTooltipSetItem", GearScore_HookRefItem)

ShoppingTooltip1:HookScript("OnTooltipSetItem", GearScore_HookCompareItem)
ShoppingTooltip2:HookScript("OnTooltipSetItem", GearScore_HookCompareItem2)
PaperDollFrame:HookScript("OnShow", MyPaperDoll)

PaperDollFrame:CreateFontString("PersonalGearScore")
PersonalGearScore:SetFont("Fonts\\FRIZQT__.TTF", 10)
PersonalGearScore:SetText("gs: 0")
PersonalGearScore:SetPoint("BOTTOMLEFT", PaperDollFrame, "TOPLEFT", 72, -253)
PersonalGearScore:Show()

PaperDollFrame:CreateFontString("GearScoreLabel")
GearScoreLabel:SetFont("Fonts\\FRIZQT__.TTF", 10)
GearScoreLabel:SetText("GearScore")
GearScoreLabel:SetPoint("BOTTOMLEFT", PaperDollFrame, "TOPLEFT", 72, -265)
GearScoreLabel:Show()

PaperDollFrame:CreateFontString("PersonalItemLevel")
PersonalItemLevel:SetFont("Fonts\\FRIZQT__.TTF", 10)
PersonalItemLevel:SetText("ilvl: 0")
PersonalItemLevel:SetPoint("BOTTOMRIGHT", PaperDollFrame, "TOPRIGHT", -90, -253)
PersonalItemLevel:Show()

PaperDollFrame:CreateFontString("ItemLevelLabel")
ItemLevelLabel:SetFont("Fonts\\FRIZQT__.TTF", 10)
ItemLevelLabel:SetText("ItemLevel")
ItemLevelLabel:SetPoint("BOTTOMRIGHT", PaperDollFrame, "TOPRIGHT", -90, -265)
ItemLevelLabel:Show()

SlashCmdList["OGS"] = GS_MANSET
SLASH_OGS1 = "/gs"
SLASH_OGS2 = "/ogs"
SLASH_OGS3 = "/gearscore"
