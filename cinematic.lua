local frame_HandleCinematicStart = CreateFrame("Frame");
frame_HandleCinematicStart:RegisterEvent("CINEMATIC_START")
frame_HandleCinematicStart:SetScript("OnEvent", function(self, event, ...)
  --Skipping Cinematics causes problems QQ
  --StopCinematic()
end)
