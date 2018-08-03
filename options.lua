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
      forceSameWeaponTypeStrict = false
      print("forceSameWeaponTypeStrict",false)
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
      forceSameWeaponType = true
      print("forceSameWeaponType:",true)
      print("forceSameWeaponTypeStrict:",true)
    end
  end

  if (cmd == "replaceTier") then
    replaceTierIncrease = val
    print("replaceTierIncrease:",val)
  end
  if (cmd == "on") then
    _turnOn()
    bfaOn = true
  end
  if (cmd == "off") then
    _turnOff()
    bfaOn = false
  end
  if (cmd == "turn_in") then
    if (turnIn == false) then
      print("Turning Turn In On")
      turnIn = true
    else
      print("Turning Turn In Off")
      turnIn = false
    end

  end
  if (cmd == "opts") then
    print("BFA Enabled:",bfaOn)
    print("replaceTierIncrease:",replaceTierIncrease)
    print("forceSameWeaponType:",forceSameWeaponType)
    print("forceSameWeaponTypeStrict:",forceSameWeaponTypeStrict)
  end
  if (cmd == "help") then
    print("'/bfa opts' to print options.")
    print("'/bfa sameWepType [1,0]' without bracket to set wether or not to force the same weapon type, I.E. using a 2 Hander")
    print("'/bfa sameWepTypeStrict [1,0]' without bracket to set wether or not to force exact weapon type, I.E. daggers")
    print("'/bfa [on,off]' to enable/disable")
  end

end

SLASH_BFASSIST1 = '/bfa'

SlashCmdList["BFASSIST"] = MsgCommands   -- add /hiw and /hellow to command list
