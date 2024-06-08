-- @author Luiza177
-- @version 1.0
-- @noindex
-- @changelog
--    - v1.0 - init

local scriptSection = ({reaper.get_action_context()})[3]
local scriptId = ({reaper.get_action_context()})[4]

reaper.Main_OnCommand(40749, 0) --Options: Set loop points linked to time selection

-- local preRoll_record = reaper.GetToggleCommandState(41819) --Pre-roll: Toggle pre-roll on record
-- if preRoll_record == 0 then reaper.Main_OnCommand(41819) end

reaper.Main_OnCommand(40252, 0) --Record: Set record mode to normal

-- local loop = reaper.GetToggleCommandState(1068) --Transport: Toggle repeat
-- if loop == 1 then reaper.Main_OnCommand(1068, 0) end

local timeSelectionPreRoll = reaper.NamedCommandLookup("_RScb800d59f8df1804837dea5c51d5a2bc34ee6fe9")
local loopMode = reaper.NamedCommandLookup("_RS39bc6a78cca723e8c317548b1d724f540187c51b")

reaper.SetExtState("luiza177_recordMode", "TimeSelectionPreRoll", "0", true)
reaper.SetExtState("luiza177_recordMode", "Normal", "1", true)
reaper.SetExtState("luiza177_recordMode", "Loop", "0", true)
reaper.SetToggleCommandState(scriptSection, scriptId, 1)
reaper.SetToggleCommandState(scriptSection, timeSelectionPreRoll, 0)
reaper.SetToggleCommandState(scriptSection, loopMode, 0)
reaper.RefreshToolbar2(scriptSection, scriptId)