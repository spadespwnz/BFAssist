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
replaceTierIncrease = 50
forceSameWeaponType = false
forceSameWeaponTypeStrict = false

toEquip = {}
checkEquip = false
equipAfterCombat = false
--/run print(select(1,GetDetailedItemLevelInfo(GetInventoryItemLink("player", GetInventorySlotInfo( "ShoulderSlot" )))))
--/run print(select(4,GetItemInfo(GetInventoryItemLink("player", GetInventorySlotInfo( "ShoulderSlot" )))))

--local ItemUpgradeInfo = LibStub("LibItemUpgradeInfo-1.0")
--local ilevel = ItemUpgradeInfo:GetUpgradedItemLevel(GetInventoryItemLink("player", GetInventorySlotInfo( "ShoulderSlot" )))

local frame_HandleLoot = CreateFrame("Frame")
frame_HandleLoot:RegisterEvent("LOOT_OPENED")
--frame_HandleLoot:RegisterEvent("LOOT_READY")
frame_HandleLoot:SetScript("OnEvent", function(self,event,...)
  for i=1,GetNumLootItems() do
     --_,name,_,rarity,_,isQuest,questID = GetLootSlotInfo(i)
     _, _, _, _, _, _, isQuest, _, _ = GetLootSlotInfo(i)
    if(isQuest) then
      LootSlot(i)
      --[[for j=0,GetNumQuestLogEntries() do
        _,_,_,_,_,_,_,quest = GetQuestLogTitle(i)
        if(questID == quest) do
          LootSlot(i)
        end
      end
      --]]
    end
    --if (rarity > 1) then
      --LootSlot(i)
    --end
  end
end)


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
local function _findMainStat()
  local mainStat = 1
  local statValue = UnitStat("player", 1)
  local statString = "Strength"

  stat = UnitStat("player", 2)
  if (stat > statValue) then
    mainStat = 2
    statValue = stat
    statString = "Agility"
  end
  stat = UnitStat("player", 4)
  if (stat > statValue) then
    mainStat = 4
    statValue = stat
    statString = "Intellect"
  end
  return mainStat, statValue, statString
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
local frame_HandleCombatChange = CreateFrame("Frame");
frame_HandleCombatChange:RegisterEvent("PLAYER_REGEN_ENABLED")
frame_HandleCombatChange:SetScript("OnEvent", function(self,event, ...)
  for i=#toEquip,1,-1 do
    print("Equipping: ",toEquip[i])
    EquipItemByName(toEquip[i])
    table.remove(toEquip, i)
  end
  equipAfterCombat = false
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
      --[[
      for _, item in ipairs(toEquip) do
        print(item)
        EquipItemByName(item)
      end
      --]]
      if #toEquip > 0 then
        if InCombatLockdown() == true then
          equipAfterCombat = true
          return
        end
      end
      for i=#toEquip,1,-1 do
        print("Equipping: ",toEquip[i])
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
      local continueCheck = true
      name, _,_,_,_ = GetQuestItemInfo("choice", i)
      itemLink = GetQuestItemLink("choice", i)
      --rewardLevel = select(4,GetItemInfo(itemLink))
      rewardLevel = _getItemLevelLink(itemLink)
      itemType = select(9,GetItemInfo(itemLink))
      itemSubtype = select(7,GetItemInfo(itemLink))

      invItemLink = GetInventoryItemLink("player", GetInventorySlotInfo( itemEquipLocMap[itemType] ))
      local isWeapon = false
      if (itemEquipLocMap[itemType] == "SecondaryHandSlot" or itemEquipLocMap[itemType] == "MainHandSlot") then
        isWeapon = true
      end
      --Check Weapon Stuff First
      if invItemLink then
        if isWeapon then

          --Add check for main stat
          continueCheck = false
          local bestInc = 0
          if (itemType == "INVTYPE_2HWEAPON") then
            equipType = select(9, GetItemInfo(invItemLink))
            if (equipType == itemType) then
              equipSubtype = select(7, GetItemInfo(invItemLink))
              if (equipSubtype == itemSubtype and forceSameWeaponTypeStrict) or (forceSameWeaponTypeStrict == false) then
                local wepOneLevel = _getItemLevelLink(invItemLink)
                print("wepOneLevel: ",wepOneLevel)
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
            else
              --Not Wearing a 2H

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
          else
            if (forceSameWeaponType) then
              --Check vs Main
              local itemToCheck = GetInventoryItemLink("player", GetInventorySlotInfo( "MainHandSlot"))
              if itemToCheck then
                local equipType = select(9, GetItemInfo(itemToCheck))
                if equipType == itemType then
                  local equipSubtype = select(7,GetItemInfo(itemToCheck))
                  if (forceSameWeaponTypeStrict == false or equipSubtype == itemSubtype) then
                    local ilvl = _getItemLevelLink(itemToCheck)
                    if (rewardLevel < ilvl) then
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
                    if (rewardLevel < ilvl) then

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
                if (equipType == "INVTYPE_2HWEAPON") then
                  local ilvl = 0
                  if (itemEquipLocMap[itemType] == "MainHandSlot") then
                    ilvl = _bestItemMainhand()
                  else
                    ilvl = _bestItemForSlot("SecondaryHandSlot")
                  end
                  if rewardLevel - ilvl > 0 then
                    bestInc = rewardLevel - ilvl
                  end
                else
                  if itemEquipLocMap[itemType] == "SecondaryHandSlot" then
                    local ilvl = _getItemLevelLink(invItemLink)
                    if (rewardLevel > ilvl) then
                      local tempInc = rewardLevel - ilvl
                      if tempInc > bestInc then
                        bestInc = tempInc
                      end
                    end
                  else
                    local ilvl = _getItemLevelLink(invItemLink)
                    if (rewardLevel > ilvl) then
                      local tempInc = rewardLevel - ilvl
                      if tempInc > bestInc then
                        bestInc = tempInc
                      end
                    end

                    local secondaryItem = GetInventoryItemLink("player", GetInventorySlotInfo( "SecondaryHandSlot"))
                    if (secondItem) then
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
          print("Increase form",i,": ",bestInc)
          if bestInc > bestIncrease then
            print("New Best Option, Weapon: ",i)

            bestIncrease = bestInc
            bestOption = i
          end
        end
      else
        if (forceSameWeaponType == false and itemEquipLocMap[itemType] == "SecondaryHandSlot") then
          local bestInInv = _bestItemForSlot("SecondaryHandSlot")
          local inc = rewardLevel - bestInInv
          if inc > bestIncrease then
            print("New Best Option, Missing Secondary: ",i)
            bestIncrease = inc
            bestOption = i
          end
        end
        continueCheck = false
      end



      if continueCheck then
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
      --GetQuestReward(bestOption)
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
      --GetQuestReward(bestOption)
      return
    end
    isWeapon = false
    if (itemEquipLocMap[itemType] == "MainHandSlot" or itemEquipLocMap[itemType] == "SecondaryHandSlot") then
      isWeapon = true
    end

    if (isWeapon) then
      print("Equipping to Weapon Slot")
      print("Need code to equip weapon stuff still")
      return
    end
    table.insert(toEquip, itemLink)

    --GetQuestReward(bestOption)

    --EquipItemByName(itemLink)
  end
end)
