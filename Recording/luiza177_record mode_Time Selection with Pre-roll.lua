-- @author Luiza177
-- @version 1.0
-- @noindex
-- @changelog
--    - v1.0 - init

local scriptSection = ({reaper.get_action_context()})[3]
local scriptId = ({reaper.get_action_context()})[4]

reaper.Main_OnCommand(40749, 0) --Options: Set loop points linked to time selection

local preRoll_record = reaper.GetToggleCommandState(41819) --Pre-roll: Toggle pre-roll on record
if preRoll_record == 0 then reaper.Main_OnCommand(41819, 0) end

reaper.Main_OnCommand(40076, 0) --Record: Set record mode to time selection auto-punch

local loop = reaper.GetToggleCommandState(1068) --Transport: Toggle repeat
if loop == 1 then reaper.Main_OnCommand(1068, 0) end

local normal = reaper.NamedCommandLookup("_RSb1fc8a95e1a9d49d2f2c8832418adab7389678f9")
local loopMode = reaper.NamedCommandLookup("_RS39bc6a78cca723e8c317548b1d724f540187c51b")

reaper.SetExtState("luiza177_recordMode", "TimeSelectionPreRoll", "1", true)
reaper.SetExtState("luiza177_recordMode", "Normal", "0", true)
reaper.SetExtState("luiza177_recordMode", "Loop", "0", true)
reaper.SetToggleCommandState(scriptSection, scriptId, 1)
reaper.SetToggleCommandState(scriptSection, normal, 0)
reaper.SetToggleCommandState(scriptSection, loopMode, 0)
reaper.RefreshToolbar2(scriptSection, scriptId)