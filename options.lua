local function MsgCommands(msg, editbox)
  cmd = ""
  value = -1
  for i in string.gmatch(msg, "%S+") do
    if tonumber(i) ~= nil then
      value = i
    else
      cmd = i
    end
  end

  if (cmd == "sameWepType") then
    forceSameWeaponType = value
    print("forceSameWeaponType:",value)
  end
  if (cmd == "sameWepTypeStrict") then
    forceSameWeaponTypeStrict = value
    print("forceSameWeaponTypeStrict:",value)
  end
  if (cmd == "replaceTier") then
    replaceTierIncrease = value
    print("replaceTierIncrease:",value)
  end
end

SLASH_BFASSIST = '/bfa'

SlashCmdList["BFASSIST"] = MsgCommands   -- add /hiw and /hellow to command list
