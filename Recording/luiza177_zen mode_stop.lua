-- @author Luiza177
-- @version 1.0
-- @noindex
-- @changelog
--    - v1.0 - init

-- scriptSection = ({reaper.get_action_context()})[3]
scriptId = ({reaper.get_action_context()})[4]
smartRecord = reaper.NamedCommandLookup("_RS2ee92013ae3ede3af26973bce1d8d7f0afb01197")
smartPlay = reaper.NamedCommandLookup("")

reaper.Main_OnCommand(1016, 0) -- Transport: Stop

-- reaper.SetExtState("luiza177_zenRecording", "play", "0", true)
reaper.SetToggleCommandState(0, smartPlay, "0") -- main = 0

-- reaper.SetExtState("luiza177_zenRecording", "recording", "0", true)
reaper.SetToggleCommandState(0, smartRecord, "0") -- main = 0

-- reaper.SetExtState("luiza177_zenRecording", "stop", "1", true)
reaper.SetToggleCommandState(0, scriptId, "1") -- main = 0

reaper.RefreshToolbar2(0, smartRecord)

-- TODO: create Play/Stop version?