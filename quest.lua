--[[
local mapOverlay = CreateFrame("Frame", "MapOverlay",WorldMapFrame)
mapOverlay:SetFrameLevel(100)
mapOverlay:SetFrameStrata("HIGH")
mapOverlay:SetHeight(512)
mapOverlay:SetWidth(512)

mapOverlay.tex =  mapOverlay:CreateTexture()
mapOverlay.tex:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp")
mapOverlay.tex:SetAllPoints(mapOverlay)

mapOverlay.line = mapOverlay:CreateTexture()
mapOverlay.line:SetColorTexture(1,0,0,.5)
mapOverlay.line:SetAllPoints(mapOverlay)

mapOverlay:SetPoint("CENTER", 400,0)
mapOverlay:Show()
--]]

itemEquipLocMap = {};
itemEquipLocMap["INVTYPE_HEAD"]	=	"HeadSlot"
itemEquipLocMap["INVTYPE_NECK"]	=	"NeckSlot"
itemEquipLocMap["INVTYPE_SHOULDER"]	=	"ShoulderSlot"
itemEquipLocMap["INVTYPE_BODY"]	=	"ShirtSlot"
itemEquipLocMap["INVTYPE_CHEST"]	=	"ChestSlot"
itemEquipLocMap["INVTYPE_ROBE"]	=	"ChestSlot"
itemEquipLocMap["INVTYPE_WAIST"]	=	"WaistSlot"
itemEquipLocMap["INVTYPE_LEGS"]	=	"LegsSlot"
itemEquipLocMap["INVTYPE_FEET"]	=	"FeetSlot"
itemEquipLocMap["INVTYPE_WRIST"]	=	"WristSlot"
itemEquipLocMap["INVTYPE_HAND"]	=	"HandsSlot"
itemEquipLocMap["INVTYPE_FINGER"]	=	"Finger0Slot"
itemEquipLocMap["INVTYPE_FINGER_1"]	=	"Finger1Slot"
itemEquipLocMap["INVTYPE_TRINKET"]	=	"Trinket0Slot"
itemEquipLocMap["INVTYPE_TRINKET_1"]	=	"Trinket1Slot"
itemEquipLocMap["INVTYPE_CLOAK"]	=	"BackSlot"
itemEquipLocMap["INVTYPE_WEAPON"]	=	"MainHandSlot"
itemEquipLocMap["INVTYPE_SHIELD"]	=	"SecondaryHandSlot"
itemEquipLocMap["INVTYPE_2HWEAPON"]	=	"MainHandSlot"
itemEquipLocMap["INVTYPE_WEAPONMAINHAND"]	=	"MainHandSlot"
itemEquipLocMap["INVTYPE_WEAPONOFFHAND"]	=	"SecondaryHandSlot"
itemEquipLocMap["INVTYPE_HOLDABLE"]	=	"SecondaryHandSlot"
tierSlots = {"HeadSlot","ChestSlot","ShoulderSlot","LegsSlot", "BackSlot","HandsSlot"}

--Options, Must make persistant
keepSetsLegosTill115 = false
replaceTierIncrease = 50
forceSameWeaponType = false
forceSameWeaponTypeStrict = false
bfaOn = true
turnIn = true
questBar = false
local toEquip = {}
local backupEquip = {}
local checkEquip = false
local equipAfterCombat = false
local checkGearChange = false
local questBarId = nil
--/run print(select(1,GetDetailedItemLevelInfo(GetInventoryItemLink("player", GetInventorySlotInfo( "ShoulderSlot" )))))
--/run print(select(4,GetItemInfo(GetInventoryItemLink("player", GetInventorySlotInfo( "ShoulderSlot" )))))

--local ItemUpgradeInfo = LibStub("LibItemUpgradeInfo-1.0")
--local ilevel = ItemUpgradeInfo:GetUpgradedItemLevel(GetInventoryItemLink("player", GetInventorySlotInfo( "ShoulderSlot" )))




local scantip = CreateFrame("GameTooltip", "iLvlScanningTooltip", nil, "GameTooltipTemplate")

local function _isLego(slotName)
  worked, _,_,rarity = pcall(GetItemInfo,GetInventoryItemLink("player", GetInventorySlotInfo( slotName )))
  if worked then
    if rarity == 5 then
      return true
    else
      return false
    end
  else
    return false
  end
end

local function _isArtifact(slotName)
  worked, _,_,rarity = pcall(GetItemInfo,GetInventoryItemLink("player", GetInventorySlotInfo( slotName )))
  if worked then
    if rarity == 6 then
      return true
    else
      return false
    end
  else
    return false
  end
end


local function _isTier(unit, slotName)
  worked, _,_,_,_,_, _,_,_,_,_, _,_,_,_,_, setId = pcall(GetItemInfo,GetInventoryItemLink("player", GetInventorySlotInfo( slotName )))
  if (worked) then
    if setId then
      return 1
    else
      return 0
    end
  else
    return 0
  end
end

local function _getTierCount()
  local tierCount = 0
  for _, piece in ipairs(tierSlots) do
    if (_isTier("player", piece)) == 1 then
      tierCount = tierCount + 1
    end
  end
  return tierCount
end

--[[
for k,v in pairs(itemEquipLocMap) do
  print(v," ", _isTier("player", v))
end
--]]

--Auto Loot quest items

local scantip = CreateFrame("GameTooltip", "iLvlScanningTooltip", nil, "GameTooltipTemplate")
local function _findMainStat()
  local mainStat = 1
  local statValue = UnitStat("player", 1)
  local statString = "STRENGTH"

  stat = UnitStat("player", 2)
  if (stat > statValue) then
    mainStat = 2
    statValue = stat
    statString = "AGILITY"
  end
  stat = UnitStat("player", 4)
  if (stat > statValue) then
    mainStat = 4
    statValue = stat
    statString = "INTELLECT"
  end
  return mainStat, statValue, statString
end

--Only works on english version, too lazy to find _G index of Use: text
local function _isUseItem(link)
  scantip:SetOwner(UIParent, "ANCHOR_NONE")
  item = scantip:SetHyperlink(link)
  for i = 2, scantip:NumLines() do
    local text = _G["iLvlScanningTooltipTextLeft"..i]:GetText()
    if text and text ~= "" then
	    if string.find(text, "Use:") then
        return true
      end
  	end
  end
  return false
end

local function _isAzerite(link)
  azerite = false
  scantip:SetOwner(UIParent, "ANCHOR_NONE")
  item = scantip:SetHyperlink(link)
  for i = 2, scantip:NumLines() do
    local text = _G["iLvlScanningTooltipTextLeft"..i]:GetText()
    if text and text ~= "" then
	    if string.find(text, ITEM_AZERITE_EMPOWERED_VIEWABLE) then
        return true
      end
  	end
  end
  return false
end
local function _getItemLevelLink(link)
  scantip:SetOwner(UIParent, "ANCHOR_NONE")
  item = scantip:SetHyperlink(link)
  for i = 2, scantip:NumLines() do
    local text = _G["iLvlScanningTooltipTextLeft"..i]:GetText()
    if text and text ~= "" then
			realItemLevel = strmatch(text, "^" .. gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
			if realItemLevel then

				return tonumber(realItemLevel)
			end
  	end
  end
  return 0
end

local function _getItemLevelInventory(bag, slot)
  scantip:SetOwner(UIParent, "ANCHOR_NONE")
  item = scantip:SetBagItem(bag,slot)
  for i = 2, scantip:NumLines() do
    local text = _G["iLvlScanningTooltipTextLeft"..i]:GetText()
    if text and text ~= "" then
			realItemLevel = strmatch(text, "^" .. gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
			if realItemLevel then

				return tonumber(realItemLevel)
			end
  	end
  end
  return 0
end

local function _getItemLevel(unit, slotName)
  scantip:SetOwner(UIParent, "ANCHOR_NONE")
  item,i2,i3 = scantip:SetInventoryItem(unit, GetInventorySlotInfo( slotName ) )
  if not item then return nil end
  for i = 2, scantip:NumLines() do
    local text = _G["iLvlScanningTooltipTextLeft"..i]:GetText()
    if text and text ~= "" then
			realItemLevel = strmatch(text, "^" .. gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
			if realItemLevel then
				return tonumber(realItemLevel)
			end
  	end
  end
  return 0
end


local function _bestItemMainhand()
  local bestLvl = 0
  local itemLink = nil
  for bag = 0,4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag,slot)
      if item then
        iType = select(9, GetItemInfo(item))
        iSubtype = select(7, GetItemInfo(item))
        if ("MainHandSlot" == itemEquipLocMap[iType] and (iSubtype == "INVTYPE_WEAPON" or iSubtype == "INVTYPE_WEAPONMAINHAND")) then
          ilevel = tonumber(_getItemLevelInventory(bag,slot))
          if (ilevel > bestLvl) then
            itemLink = item
            bestLvl = ilevel
          end
        end
      end
    end
  end
  return bestLvl, itemLink
end

local function _bestItemForSlot(slotName)
  local bestLvl = 0
  local itemLink = nil
  for bag = 0,4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag,slot)
      if item then
        iType = select(9, GetItemInfo(item))
        if (slotName == itemEquipLocMap[iType]) then
          ilevel = tonumber(_getItemLevelInventory(bag,slot))
          if (ilevel > bestLvl) then
            itemLink = item
            bestLvl = ilevel
          end

        end
      end
    end
  end
  return bestLvl, itemLink
end


--Quest Bar Functions
local function _clearQuestItemSlots()
  ClearCursor()
  for i=1,12 do
    PickupAction(12*(questBarId-1)+i)
    ClearCursor()
  end
end
local function _addItemToBarSlot(bag,bagSlot,barSlot)
  ClearCursor()
  barSlot = (questBarId-1)*12+(barSlot+1)
  PickupContainerItem(bag,bagSlot)
  PickupAction(barSlot)
end
local function _searchBagsForQuestItems()
  if (questBarId == nil) then
    return
  end
  local questItemCount = 0
  _clearQuestItemSlots()
  local questItems = {}
  for bag = 0,4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag,slot)
      if item then
        iType = select(6, GetItemInfo(item))
        if iType == "Quest" then
          name = select(1, GetItemInfo(item))
          if (_isUseItem(item)) then
            print(name)
            _addItemToBarSlot(bag,slot,questItemCount)
            questItemCount = questItemCount+1
          end
        end
      end
    end
  end
end
local function _isBarFree(bar)
  for slot=1,12 do
    local actionTex = GetActionTexture((bar-1)*12+slot)
    if actionTex then
      local global_id = select(2,GetActionInfo((bar-1)*12+slot))
      local type = select(1,GetActionInfo((bar-1)*12+slot))
      if type ~= "item" then
        local spellName = GetSpellInfo(global_id)
        return false,  spellName
      end
    end
  end
  return true, nil
end
local function _findEmptyActionBar()
  for bar=1,10 do
    local free, text = _isBarFree(bar)
    if free == true then
      print("Using Bar: ",bar)
      return bar
    end
  end
  return nil
end
local function _enableQuestBar()
  questBar = true

  questBarId = _findEmptyActionBar()
  if questBarId == nil then
    print("No Free Bar for Quest Items :()")
  end
  _searchBagsForQuestItems()
end



local function equipItem(link)
  itemType = select(9, GetItemInfo(link))
  if (_isArtifact(itemEquipLocMap[itemType])) then
    print("Replacing Artifact -- This one is up to you, too lazy to write the special cases. :P Suggest replacing with ",link)
    return
  end
  if (itemEquipLocMap[itemType] == "SecondaryHandSlot") then
    --Check if we can create an upgrade by equipping a wep+new off
    secondaryIlevel = _getItemLevel("player", "SecondaryHandSlot")
    if (secondaryIlevel == nil) then --Assume ypur wearing a 2H...
      local equipLevel = _getItemLevel("player", "MainHandSlot")
      local newOffhandLevel = _getItemLevelLink(link)
      local mainHandBagLevel, mainHandBagItem = _bestItemMainhand()
      if ( ((mainhandBagLevel + newOffhandLevel)/2) > equipLevel ) then
        EquipItemByName(link)
        EquipItemByName(mainHandBagItem)
      end
    else
      EquipItemByName(link)
    end

  elseif (itemType == "INVTYPE_WEAPON" or itemType == "INVTYPE_WEAPONMAINHAND") then

    --Check if we can create an upgrade by equipping new wep+off
    if (_getItemLevel("player", "SecondaryHandSlot") == nil) then --Assume Wearing a 2H

      local offHandBagLevel, offHandBagItem = _bestItemForSlot("SecondaryHandSlot")

      local newMainhandLevel = _getItemLevelLink(link)

      local mainHand = GetInventoryItemLink("player", GetInventorySlotInfo( "MainHandSlot" ))

      local equipLevel = 0
      if mainHand ~= nil then --Has mainhand, check its ilevel
         equipLevel = _getItemLevel("player", "MainHandSlot")
      end
      if ( ((newMainhandLevel + offHandBagLevel)/2) > equipLevel ) then
        EquipItemByName(link)
        EquipItemByName(offHandBagItem)
      end
    else
      EquipItemByName(link)
    end
  else
    if keepSetsLegosTill115 == true then
      if UnitLevel("player") < 116 then
        if itemType == "INVTYPE_FINGER" then
          if _isLego("Finger0Slot") or _isLego("Finger1Slot") then
            local level1 = _getItemLevel("player", "Finger0Slot")
            local level2 = _getItemLevel("player", "Finger1Slot")
            if level1 <= level2 then
              if isLego("Finger0Slot") then
                return;
              end
              EquipItemByName(link)
              return
            else
              if isLego("Finger1Slot") then
                return;
              end
              EquipItemByName(link)
              return
            end
          end
          return
        end
        if itemType == "INVTYPE_TRINKET" then
          if _isLego("Trinket0Slot") or _isLego("Trinket1Slot") then
            local level1 = _getItemLevel("player", "Trinket0Slot")
            local level2 = _getItemLevel("player", "Trinket1Slot")
            if level1 <= level2 then
              if isLego("Trinket0Slot") then
                return;
              end
              EquipItemByName(link)
              return
            else
              if isLego("Trinket1Slot") then
                return;
              end
              EquipItemByName(link)
              return
            end
          end
          return
        end
        if _isLego(itemEquipLocMap[itemType]) or _isTier("player", itemEquipLocMap[itemType]) then
          return
        else
          EquipItemByName(link)
        end
      else
        EquipItemByName(link)
      end
    else
      EquipItemByName(link)
    end
  end
end

--Called 5 seconds after quest is done, redundant equip attempt incase first failed
local function _equipItemList()
  for i=#backupEquip,1,-1 do
    equipItem(backupEquip[i])
  end
end

local function tryEquipItems()
  if #toEquip > 0 then
    if InCombatLockdown() == true then
      equipAfterCombat = true
      return
    else

      for i=#toEquip,1,-1 do
        print("Equipping: ",toEquip[i])
        --checkGearChange = true
        equipItem(toEquip[i])
        table.remove(toEquip, i)
      end
    end
  end
end
function addEquip(item)
  table.insert(toEquip, item)
end


function _replaceTeirWithBagItems()
  for _,v in pairs(itemEquipLocMap) do

    --invItemLink = GetInventoryItemLink("player", GetInventorySlotInfo( itemEquipLocMap[itemType] ))
    local item = GetInventoryItemLink("player", GetInventorySlotInfo( v ))

    if _isLego(v) then
      local itemLevel = _getItemLevelLink(item)
      if v == "Finger1Slot" then
        v = "Finger0Slot"
      end
      if v == "Trinket1Slot" then
        v = "Trinket0Slot"
      end
      local bagItemLevel, bestBagItem = _bestItemForSlot(v)
      if bagItemLevel > itemLevel then
        addEquip(bestBagItem)
        tryEquipItems()
      end
    end
  end
end
local f = CreateFrame("Frame", nil);
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
  if arg1 == "BFAssist" then
    print("BFAssist is Loaded!")
    if questBar == true then
      questBarId = _findEmptyActionBar()
      if questBarId == nil then
        print("No Free Bar for Quest Items :()")
      end
    end
    _searchBagsForQuestItems()
    if bfaOn == false then
      print("BFAssist is off, type '/bfa on' to enable")
      _turnOff()
    end
  end

  --[[
  for _, slot in ipairs(tierSlots) do
    print(slot," ",_getItemLevel("player", slot))
  end
  ]]--
end)


local barUpdateQueued = false
local lastLootTime = nil

local function _updateQuestItemBar()
  barUpdateQueued = false
  print("Updating bars")
  _searchBagsForQuestItems()
end


local frame_HandleLevelUp = CreateFrame("Frame")
frame_HandleLevelUp:RegisterEvent("PLAYER_LEVEL_UP")
frame_HandleLevelUp:SetScript("OnEvent", function(self, event, newLevel)
  print("Grats on ",newLevel)
  if (newLevel == 116) then
    if keepSetsLegosTill115 then
      _replaceTierWithBagItems()
    end
  end
end)

local frame_HandleItemPush = CreateFrame("Frame")
frame_HandleItemPush:RegisterEvent("ITEM_PUSH")
frame_HandleItemPush:SetScript("OnEvent", function(self,event,...)
  lastLootTime = GetTime()
end)

local frame_HandleQuestAccepted = CreateFrame("Frame")
frame_HandleQuestAccepted:RegisterEvent("QUEST_ACCEPTED")
frame_HandleQuestAccepted:SetScript("OnEvent", function(self,event,...)
  local time = GetTime()
  if lastLootTime == nil then
    return
  end
  if time - lastLootTime < 2 then

    if barUpdateQueued == false then
      barUpdateQueued = true
      C_Timer.After(3, _updateQuestItemBar)
    end
  end
end)



local frame_HandleLoot = CreateFrame("Frame")
frame_HandleLoot:RegisterEvent("LOOT_OPENED")
frame_HandleLoot:SetScript("OnEvent", function(self,event,...)
  for i=1,GetNumLootItems() do
     _, _, _, _, _, _, isQuest, _, _ = GetLootSlotInfo(i)
    if(isQuest) then
      LootSlot(i)
    end
  end
end)

local frame_HandleCombatChange = CreateFrame("Frame");
frame_HandleCombatChange:RegisterEvent("PLAYER_REGEN_ENABLED")
frame_HandleCombatChange:SetScript("OnEvent", function(self,event, ...)
  for i=#toEquip,1,-1 do
    print("Equipping: ",toEquip[i])
    equipItem(toEquip[i])
    table.remove(toEquip, i)
  end
  equipAfterCombat = false
end)

local frame_HandleEquipChange = CreateFrame("Frame")
frame_HandleEquipChange:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame_HandleEquipChange:SetScript("OnEvent", function(self, event, ...)

end)

local frame_HandleEquipItems = CreateFrame("Frame");
--frame_HandleEquipItems:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame_HandleEquipItems:SetScript("OnEvent", function(self, event, ...)
  if #toEquip > 0 then
    if InCombatLockdown() == true then
      equipAfterCombat = true
      return
    else

      for i=#toEquip,1,-1 do
        print("Equipping: ",toEquip[i])
        checkGearChange = true
        equipItem(toEquip[i])
        --table.remove(toEquip, i)
      end
    end
  end
end)




--Quest Detail, Accept Quest Page
local frame_HandleQuestDetail = CreateFrame("Frame");
frame_HandleQuestDetail:RegisterEvent("QUEST_DETAIL")
frame_HandleQuestDetail:SetScript("OnEvent", function(self, event, ...)
  AcceptQuest()
end)


--Quest Progress, Confirm you have requred items to turn in
local frame_HandleQuestProgress = CreateFrame("Frame");
frame_HandleQuestProgress:RegisterEvent("QUEST_PROGRESS")
frame_HandleQuestProgress:SetScript("OnEvent", function(self, event, ...)
  CompleteQuest()
end)



local frame_HandleQuestGreeting = CreateFrame("Frame");
frame_HandleQuestGreeting:RegisterEvent("QUEST_GREETING")
frame_HandleQuestGreeting:SetScript("OnEvent", function(self, event, ...)
  availCount = GetNumAvailableQuests();
  if availCount > 0 then
    SelectAvailableQuest(1)
    return
  end

  active = GetNumActiveQuests()
  for i=1,active,1 do
    title,completed = GetActiveTitle(i)
    if completed == true then
      SelectActiveQuest(i)
      return
    end
  end
end)


local frame_HandleGossipShow = CreateFrame("Frame");
frame_HandleGossipShow:RegisterEvent("GOSSIP_SHOW")

frame_HandleGossipShow:SetScript("OnEvent", function(self, event, arg1,...)

  --Accept All Quests
  availCount = GetNumGossipAvailableQuests();
  if availCount > 0 then
    SelectGossipAvailableQuest(1)
    return
  end

  --Turn In Completed Quests
  active = GetNumGossipActiveQuests()
  _,_,_,one,_,_,_,_,_,two,_,_,_,_,_,three,_,_,_,_,_,four,_,_ = GetGossipActiveQuests()

  if one == true then
    SelectGossipActiveQuest(1)
    return
  end
  if two == true then
    SelectGossipActiveQuest(2)
    return
  end
  if three == true then
    SelectGossipActiveQuest(3)
    return
  end
  if four == true then
    SelectGossipActiveQuest(4)
    return
  end

  local name, _ = UnitName("target")
  if name == "Meerah" then
    return
  end
  gossip = GetNumGossipOptions()
  if gossip == 1 then
    SelectGossipOption(1)
  end
  if gossip > 1 then
    local gossipText = GetGossipText()
    if strmatch(gossipText, "What do you seek?") then
      SelectGossipOption(3)
      return
    end
    if strmatch(gossipText, "What is the lesson of the leaping tiger?") then
      SelectGossipOption(5)
      return
    end
    if strmatch(gossipText, "What is the source of power?") then
      SelectGossipOption(1)
      return
    end
    if strmatch(gossipText, "What is a life well") then
      SelectGossipOption(4)
      return
    end
    if strmatch(gossipText, "What do those with vision see?") then
      SelectGossipOption(2)
      return
    end

  end

  --Do RP Dialog
end)

--Turn in the quest

local function _getIncreaseWeaponReward(rewardLink)

  local stats = GetItemStats(itemLink)
  _,_,mainStatString = _findMainStat()
  if (stats["ITEM_MOD_"..mainStatString.."_SHORT"] == nil) then
    print(rewardLink," has no main stat.")
    return 0
  end

  local itemType = select(9,GetItemInfo(rewardLink))
  local invItemLink = GetInventoryItemLink("player", GetInventorySlotInfo( itemEquipLocMap[itemType] ))
  if invItemLink == nil then

    --Comparing Against Empty slot (possibly upgrade for 2nd slot if using a 2H)
    if (forceSameWeaponType == false and itemEquipLocMap[itemType] == "SecondaryHandSlot") then
      local bestInInv = _bestItemForSlot("SecondaryHandSlot")
      local inc = rewardLevel - bestInInv
      print("Increase over best Secondary Slot in bag")
      return inc
    elseif itemEquipLocMap[itemType] == "MainHandSlot" then --Not wearing a mainhand?
      print("Your not wearing a weapon so this is an upgrade...")
      return _getItemLevelLink(rewardLink)

    end
  end
  local bestInc = 0

  if (itemType == "INVTYPE_2HWEAPON") then --Reward is 2H
    equipType = select(9, GetItemInfo(invItemLink))
    if (equipType == itemType) then --Wearing 2H Weapon
      equipSubtype = select(7, GetItemInfo(invItemLink))
      if (equipSubtype == itemSubtype and forceSameWeaponTypeStrict) or (forceSameWeaponTypeStrict == false) then
        local wepOneLevel = _getItemLevelLink(invItemLink)
        if rewardLevel > wepOneLevel then
          bestInc = rewardLevel - wepOneLevel
        end
      end
      --Check For 2nd 2H
      secondInvItemLink = GetInventoryItemLink("player", GetInventorySlotInfo( "SecondaryHandSlot" ))
      if (secondInvItemLink) then
        secondEquipType = select(9, GetItemInfo(secondInvItemLink))
        if secondEquipType == itemType then
          secondEquipSubtype = select(7, GetItemInfo(secondInvItemLink))

          if (secondEquipSubtype == itemSubtype and forceSameWeaponTypeStrict) or (forceSameWeaponTypeStrict == false) then
            local wepTwoLevel = _getItemLevelLink(secondInvItemLink)
            local dif = rewardLevel - wepTwoLevel
            if dif > bestInc then
              bestInc = dif
            end
          end
        end
      end
    else --Wearing 1H

      if (forceSameWeaponType == false) then

        --Get Average Ilevel of 2 slots and compare
        local ilvlOne = _getItemLevelLink(invItemLink)
        local ilvlTwo = 0

        secondInvItemLink = GetInventoryItemLink("player", GetInventorySlotInfo( "SecondaryHandSlot" ))
        if (secondInvItemLink) then
          ilvlTwo = _getItemLevelLink(secondInvItemLink)
        end
        local ilvl = (ilvlOne + ilvlTwo) / 2
        if rewardLevel > ilvl then
          bestInc = rewardLevel - ilvl
        end
      end
    end
  else --Reward is 1H
    if (forceSameWeaponType) then
      --Check vs Main


      local itemToCheck = GetInventoryItemLink("player", GetInventorySlotInfo( "MainHandSlot"))
      if itemToCheck then
        local equipType = select(9, GetItemInfo(itemToCheck))
        if equipType == itemType then

          local equipSubtype = select(7,GetItemInfo(itemToCheck))
          if (forceSameWeaponTypeStrict == false or equipSubtype == itemSubtype) then

            local ilvl = _getItemLevelLink(itemToCheck)
            if (rewardLevel > ilvl) then
              bestInc = rewardLevel - ilvl
            end
          end
        end
      end

      --Check vs Off
      itemToCheck = GetInventoryItemLink("player", GetInventorySlotInfo( "SecondaryHandSlot"))
      if itemToCheck then

        local equipType = select(9, GetItemInfo(itemToCheck))
        if equipType == itemType then
          local equipSubtype = select(7,GetItemInfo(itemToCheck))
          if (forceSameWeaponTypeStrict == false or equipSubtype == itemSubtype) then

            local ilvl = _getItemLevelLink(itemToCheck)
            if (rewardLevel > ilvl) then
              local tempInc = rewardLevel - ilvl
              if tempInc > bestInc then
                bestInc = tempInc
              end
            end
          end
        end
      end

    else
      --If wearing a 2H, compare against inv's best item for slot
      --else, if secondary, compare against secondary
      --else, if primary, compare against primary and secondary is same type
      local itemToCheck = GetInventoryItemLink("player", GetInventorySlotInfo( "MainHandSlot"))
      if itemToCheck then
        local equipType = select(9, GetItemInfo(itemToCheck))
        if (equipType == "INVTYPE_2HWEAPON") then --Wearing a 2H
          local ilvl = 0
          if (itemEquipLocMap[itemType] == "MainHandSlot") then
            ilvl = _bestItemMainhand()
          else
            ilvl = _bestItemForSlot("SecondaryHandSlot")
          end
          if rewardLevel - ilvl > 0 then
            bestInc = rewardLevel - ilvl
          end
        else --Not wearing a 2H
          if itemEquipLocMap[itemType] == "SecondaryHandSlot" then --Reward is 2ndary
            local ilvl = _getItemLevelLink(invItemLink)
            if (rewardLevel > ilvl) then
              local tempInc = rewardLevel - ilvl
              if tempInc > bestInc then
                bestInc = tempInc
              end
            end
          else --Reward is 1Handed primary

            local ilvl = _getItemLevelLink(invItemLink)
            if (rewardLevel > ilvl) then
              local tempInc = rewardLevel - ilvl
              if tempInc > bestInc then
                bestInc = tempInc
              end
            end

            local secondaryItem = GetInventoryItemLink("player", GetInventorySlotInfo( "SecondaryHandSlot"))
            if (secondaryItem) then

              local ilvl = _getItemLevelLink(secondaryItem)
              if (rewardLevel > ilvl) then
                local tempInc = rewardLevel - ilvl
                if tempInc > bestInc then
                  bestInc = tempInc
                end
              end
            end
          end
        end
      end
    end
  end
  return bestInc
end


local frame_HandleQuestComplete = CreateFrame("Frame");
frame_HandleQuestComplete:RegisterEvent("QUEST_COMPLETE")
frame_HandleQuestComplete:SetScript("OnEvent", function(self, event, ...)
  questOptions = GetNumQuestChoices()
  if questOptions == 0 then
    if (turnIn == true) then
      GetQuestReward(itemChoice);
    end
  else
    bestIncrease = 0
    bestOption = 1
    for i=1,questOptions do
      local continueCheck = true
      name, _,_,_,_ = GetQuestItemInfo("choice", i)
      itemLink = GetQuestItemLink("choice", i)
      if (_isAzerite(itemLink)) then
        return
      end
      rewardLevel = _getItemLevelLink(itemLink)
      itemType = select(9,GetItemInfo(itemLink))
      itemSubtype = select(7,GetItemInfo(itemLink))

      invItemLink = GetInventoryItemLink("player", GetInventorySlotInfo( itemEquipLocMap[itemType] ))
      local isWeapon = false
      if (itemEquipLocMap[itemType] == "SecondaryHandSlot" or itemEquipLocMap[itemType] == "MainHandSlot") then
        isWeapon = true
      end

      if isWeapon then
        continueCheck = false
        itemInc = _getIncreaseWeaponReward(itemLink)
        if itemInc > bestIncrease then
          bestOption = i
          bestIncrease = itemInc
        end
      end

      if continueCheck then
        --invLevel = select(4, GetItemInfo(invItemLink))
        invLevel = _getItemLevel("player", itemEquipLocMap[itemType])
        isTier = _isTier("player", itemEquipLocMap[itemType])

        if (isTier) == 1 then
          tierCount = _getTierCount()
          if (tierCount == 4 or tierCount == 2) then
            --Find Best Item For Slot In Bag
            bestLevelInBag = _bestItemForSlot(itemEquipLocMap[itemType])
            if (bestLevelInBag > invLevel) then
              invLevel = bestLevelInBag
            end
          end
        end

        if itemType == "INVTYPE_FINGER" then
          otherInvLevel = _getItemLevel("player",  itemEquipLocMap["INVTYPE_FINGER_1"] )
          if otherInvLevel < invLevel then
            invLevel = otherInvLevel
          end
        end

        if itemType == "INVTYPE_TRINKET" then
          otherInvLevel = _getItemLevel("player",  itemEquipLocMap["INVTYPE_TRINKET_1"] )
          if otherInvLevel < invLevel then
            invLevel = otherInvLevel
          end
        end


        dif = rewardLevel - invLevel
        if rewardLevel - invLevel > bestIncrease then
          bestOption = i
          bestIncrease = rewardLevel - invLevel
          print("New Best: ",bestIncrease)
        end
      end
    end

    itemLink = GetQuestItemLink("choice", bestOption)
    itemType = select(9,GetItemInfo(itemLink))


    isTier = _isTier("player", itemEquipLocMap[itemType])
    if (bestIncrease == 0) then
      print("No Upgrades")
      if (turnIn == true) then
        GetQuestReward(bestOption)
      end
      return
    end

    print("Best Upgrade:",itemLink)
    --[[
    if (itemEquipLocMap[itemType] == "MainHandSlot" or itemEquipLocMap[itemType] == "SecondaryHandSlot" ) then
      print("Not Equipping Weapon")
      GetQuestReward(bestOption)
      return
    end
    --]]
    if (isTier == 1) then
      --Check Inventory To Replace Tier
      firstItem = itemLink
      firstSlot = itemEquipLocMap[itemType]

      bestSecondOptionIncrease = 0
      secondItem = nil
      --secondItemSlot = nil
      for _, slot in ipairs(tierSlots) do
        if slot ~= firstSlot then
          if _isTier("player", slot) then
            slotLevel = _getItemLevel("player", slot)
            local bestLevel, bestItem  = _bestItemForSlot(slot)
            if bestLevel - slotLevel > bestSecondOptionIncrease then
              bestSecondOptionIncrease = bestLevel - slotLevel
              secondItem = bestItem
            end
          end
        end
      end
      if secondItem then
        increase = bestIncrease + bestSecondOptionIncrease
        print("2nd Item Increase: ",bestSecondOptionIncrease)
        print("Total Increase: ",increase)
        if (increase >= replaceTierIncrease) then
          print("Replacing 2 tier peices.")
          table.insert(toEquip, firstItem)
          table.insert(toEquip, secondItem)
          backupEquip = {unpack(toEquip)}
          print("Equipping: ",firstItem," and ",secondItem)
          --EquipItemByName(firstItem)
          --EquipItemByName(secondItem)
        end
      end
      if (turnIn == true) then
        GetQuestReward(bestOption)
      end
      C_Timer.After(1, tryEquipItems);
      C_Timer.After(5, _equipItemList); --Redundant attempt again
      return
    end
    isWeapon = false
    if (itemEquipLocMap[itemType] == "MainHandSlot" or itemEquipLocMap[itemType] == "SecondaryHandSlot") then
      isWeapon = true
    end

    if (isWeapon) then
      print("Probably equipping: ",itemLink)
      table.insert(toEquip, itemLink)

      backupEquip = {unpack(toEquip)}

      if (turnIn == true) then
        GetQuestReward(bestOption)
      end
      C_Timer.After(1, tryEquipItems);
      C_Timer.After(5, _equipItemList); --Redundant attempt again
      return
    end
    print("Equipping: ",itemLink)
    table.insert(toEquip, itemLink)
    backupEquip = {unpack(toEquip)}
    if (turnIn == true) then
      GetQuestReward(bestOption)
    end
    C_Timer.After(1, tryEquipItems);
    C_Timer.After(5, _equipItemList); --Redundant attempt again
    --EquipItemByName(itemLink)
  end
end)

function _turnOn()
  print("Turning BFAssist on")
  frame_HandleQuestComplete:RegisterEvent("QUEST_COMPLETE")
  frame_HandleGossipShow:RegisterEvent("GOSSIP_SHOW")
  frame_HandleQuestGreeting:RegisterEvent("QUEST_GREETING")
  frame_HandleQuestProgress:RegisterEvent("QUEST_PROGRESS")
  frame_HandleQuestDetail:RegisterEvent("QUEST_DETAIL")
  frame_HandleEquipChange:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  frame_HandleCombatChange:RegisterEvent("PLAYER_REGEN_ENABLED")
  frame_HandleLoot:RegisterEvent("LOOT_OPENED")
end

function _turnOff()
  print("Turning BFAssist off")
  frame_HandleQuestComplete:UnregisterEvent("QUEST_COMPLETE")
  frame_HandleGossipShow:UnregisterEvent("GOSSIP_SHOW")
  frame_HandleQuestGreeting:UnregisterEvent("QUEST_GREETING")
  frame_HandleQuestProgress:UnregisterEvent("QUEST_PROGRESS")
  frame_HandleQuestDetail:UnregisterEvent("QUEST_DETAIL")
  frame_HandleEquipChange:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
  frame_HandleCombatChange:UnregisterEvent("PLAYER_REGEN_ENABLED")
  frame_HandleLoot:UnregisterEvent("LOOT_OPENED")
end
