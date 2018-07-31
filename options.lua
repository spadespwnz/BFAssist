local function MsgCommands(msg, editbox)
  local cmd = ""
  local val = -1
  for i in string.gmatch(msg, "%S+") do
    if tonumber(i) ~= nil then
      val = tonumber(i)
    else
      cmd = i
    end
  end
  
  if (cmd == "sameWepType") then
    print(val)
    if (val == 0) then
      forceSameWeaponType = false
      print("forceSameWeaponType",false)
    elseif (val == 1) then
      forceSameWeaponType = true
      print("forceSameWeaponType:",true)
    end
  end

  if (cmd == "sameWepTypeStrict") then
    if (val == 0) then
      forceSameWeaponTypeStrict = false
      print("forceSameWeaponTypeStrict:",false)
    elseif (val == 1) then
      forceSameWeaponTypeStrict = true
      print("forceSameWeaponTypeStrict:",true)
    end
  end

  if (cmd == "replaceTier") then
    replaceTierIncrease = val
    print("replaceTierIncrease:",val)
  end
  if (cmd == "opts") then
    print("replaceTierIncrease:",replaceTierIncrease)
    print("forceSameWeaponType:",forceSameWeaponType)
    print("forceSameWeaponTypeStrict:",forceSameWeaponTypeStrict)
  end
end

SLASH_BFASSIST1 = '/bfa'

SlashCmdList["BFASSIST"] = MsgCommands   -- add /hiw and /hellow to command list
