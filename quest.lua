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

replaceTierIncrease = 50

toEquip = {}
checkEquip = false
--/run print(select(1,GetDetailedItemLevelInfo(GetInventoryItemLink("player", GetInventorySlotInfo( "ShoulderSlot" )))))
--/run print(select(4,GetItemInfo(GetInventoryItemLink("player", GetInventorySlotInfo( "ShoulderSlot" )))))

--local ItemUpgradeInfo = LibStub("LibItemUpgradeInfo-1.0")
--local ilevel = ItemUpgradeInfo:GetUpgradedItemLevel(GetInventoryItemLink("player", GetInventorySlotInfo( "ShoulderSlot" )))
local scantip = CreateFrame("GameTooltip", "iLvlScanningTooltip", nil, "GameTooltipTemplate")

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

local scantip = CreateFrame("GameTooltip", "iLvlScanningTooltip", nil, "GameTooltipTemplate")

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

local f = CreateFrame("Frame", nil);
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event, ...)
  --print(_getItemLevel("player", "ShoulderSlot"))
  print("BFAssist is Loaded!")
  --[[
  for _, slot in ipairs(tierSlots) do
    print(slot," ",_getItemLevel("player", slot))
  end
  ]]--
end)

local frame_HandleEquipItems = CreateFrame("Frame");
frame_HandleEquipItems:RegisterEvent("QUEST_FINISHED")
frame_HandleEquipItems:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame_HandleEquipItems:SetScript("OnEvent", function(self, event, ...)
  if (event == "QUEST_FINISHED") then
    checkEquip = true
  end
  if (event == "UNIT_INVENTORY_CHANGED") then
    if (checkEquip == true) then
      print("equip items")
      --[[
      for _, item in ipairs(toEquip) do
        print(item)
        EquipItemByName(item)
      end
      --]]
      for i=#toEquip,1,-1 do
        print("Item: ",toEquip[i])
        EquipItemByName(toEquip[i])
        table.remove(toEquip, i)
      end

      checkEquip = false
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
  print(event,"   ",type(event))
  CompleteQuest()
end)



local frame_HandleQuestGreeting = CreateFrame("Frame");
frame_HandleQuestGreeting:RegisterEvent("QUEST_GREETING")
frame_HandleQuestGreeting:SetScript("OnEvent", function(self, event, ...)
  print(GetNumQuestChoices())
end)


local frame_HandleGossipShow = CreateFrame("Frame");
frame_HandleGossipShow:RegisterEvent("GOSSIP_SHOW")
frame_HandleGossipShow:SetScript("OnEvent", function(self, event, ...)
  --Accept All Quests
  availCount = GetNumGossipAvailableQuests();
  if availCount > 0 then
    SelectGossipAvailableQuest(1)
    return
  end

  --Turn In Completed Quests
  active = GetNumGossipActiveQuests()
  _,_,_,one,_,_,_,two,_,_,_,three,_,_,_,four = GetGossipActiveQuests()
  if one == true then
    SelectGossipActiveQuest(1)
    return
  elseif two == true then
    SelectGossipActiveQuest(2)
    return
  elseif three == true then
    SelectGossipActiveQuest(3)
    return
  elseif four == true then
    SelectGossipActiveQuest(4)
    return
  end


  gossip = GetNumGossipOptions()
  if gossip == 1 then
    SelectGossipOption(1)
  end

  --Do RP Dialog
end)

--Turn in the quest
local frame_HandleQuestComplete = CreateFrame("Frame");
frame_HandleQuestComplete:RegisterEvent("QUEST_COMPLETE")
frame_HandleQuestComplete:SetScript("OnEvent", function(self, event, ...)
  questOptions = GetNumQuestChoices()

  if questOptions == 0 then
    GetQuestReward(itemChoice);
  else
    bestIncrease = 0
    bestOption = 1
    for i=1,questOptions do
      name, _,_,_,_ = GetQuestItemInfo("choice", i)
      itemLink = GetQuestItemLink("choice", i)
      --rewardLevel = select(4,GetItemInfo(itemLink))
      rewardLevel = _getItemLevelLink(itemLink)
      itemType = select(9,GetItemInfo(itemLink))


      invItemLink = GetInventoryItemLink("player", GetInventorySlotInfo( itemEquipLocMap[itemType] ))
      if invItemLink then
        --invLevel = select(4, GetItemInfo(invItemLink))
        invLevel = _getItemLevel("player", itemEquipLocMap[itemType])
        print("-----Checking Reward ",i,"------")
        print("Reward Ilevel: ",rewardLevel)
        print("Equipped Level: ",invLevel)
        isTier = _isTier("player", itemEquipLocMap[itemType])

        if (isTier) == 1 then
          print("Equipped Item is Teir")
          tierCount = _getTierCount()
          if (tierCount == 4 or tierCount == 2) then
            --Find Best Item For Slot In Bag
            bestLevelInBag = _bestItemForSlot(itemEquipLocMap[itemType])
            print("Best Item In Bag for Slot: ", bestLevelInBag)
            if (bestLevelInBag > invLevel) then
              invLevel = bestLevelInBag
              print("Bag Piece is better, Checking Against: ",invLevel)
            end
          else
            print("Odd Number Of Teir, Skipping Bag Checks")
          end
        end

        if itemType == "INVTYPE_FINGER" then
          print("Reward is Finger, Must Check Both")
          otherInvLevel = _getItemLevel("player",  itemEquipLocMap["INVTYPE_FINGER_1"] )
          print("2nd Finger: ",otherInvLevel)
          if otherInvLevel < invLevel then
            invLevel = otherInvLevel
            print("2nd Finger Is Better")
          end
        end

        if itemType == "INVTYPE_TRINKET" then
          print("Reward is Trinket, Must Check Both")
          otherInvLevel = _getItemLevel("player",  itemEquipLocMap["INVTYPE_TRINKET_1"] )
          print("2nd Trinket: ",otherInvLevel)
          if otherInvLevel < invLevel then
            invLevel = otherInvLevel
          print("2nd Trinket Is Better")
          end
        end


        dif = rewardLevel - invLevel
        print("Reward: ",rewardLevel, " vs: ",invLevel," Dif: ",dif)
        print("Previous Best: ",bestIncrease)
        if rewardLevel - invLevel > bestIncrease then
          bestOption = i
          bestIncrease = rewardLevel - invLevel
          print("New Best: ",bestIncrease)
        else
          print("Previous Option Was Better")
        end
      end
    end
    print("Best Option: ",bestOption)

    itemLink = GetQuestItemLink("choice", bestOption)
    itemType = select(9,GetItemInfo(itemLink))


    isTier = _isTier("player", itemEquipLocMap[itemType])
    if (bestIncrease == 0) then
      print("Item is not an upgrade")
      GetQuestReward(bestOption)
      return
    end
    --[[
    if (itemEquipLocMap[itemType] == "MainHandSlot" or itemEquipLocMap[itemType] == "SecondaryHandSlot" ) then
      print("Not Equipping Weapon")
      GetQuestReward(bestOption)
      return
    end
    --]]
    if (isTier == 1) then
      print("Check To Replace Tier")
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
          --EquipItemByName(firstItem)
          --EquipItemByName(secondItem)
        end
      end
      GetQuestReward(bestOption)
      return
    end

    table.insert(toEquip, itemLink)
    GetQuestReward(bestOption)
    --EquipItemByName(itemLink)
  end
end)
