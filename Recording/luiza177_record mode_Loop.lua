-- @author Luiza177
-- @version 1.0
-- @noindex
-- @changelog
--    - v1.0 - init

local scriptSection = ({reaper.get_action_context()})[3]
local scriptId = ({reaper.get_action_context()})[4]

reaper.Main_OnCommand(40750, 0) --Options: Unset loop points linked to time selection

reaper.Main_OnCommand(40631, 0) --Go to end of time selection
reaper.Main_OnCommand(40839, 0) --Move edit cursor forward one measure (no seek)
reaper.Main_OnCommand(40223, 0) --Loop points: Set end point
reaper.Main_OnCommand(40630, 0) --Go to start of time selection
reaper.Main_OnCommand(40840, 0) --Move edit cursor back one measure (no seek)
reaper.Main_OnCommand(40840, 0) --Move edit cursor back one measure (no seek)
reaper.Main_OnCommand(40222, 0) --Loop points: Set start point

local preRoll_record = reaper.GetToggleCommandState(41819) --Pre-roll: Toggle pre-roll on record
if preRoll_record == 1 then reaper.Main_OnCommand(41819, 0) end

reaper.Main_OnCommand(40076, 0) --Record: Set record mode to time selection auto-punch

local loop = reaper.GetToggleCommandState(1068) --Transport: Toggle repeat
if loop == 0 then reaper.Main_OnCommand(1068, 0) end

local timeSelectionPreRoll = reaper.NamedCommandLookup("_RScb800d59f8df1804837dea5c51d5a2bc34ee6fe9")
local normal = reaper.NamedCommandLookup("_RSb1fc8a95e1a9d49d2f2c8832418adab7389678f9")

reaper.SetExtState("luiza177_recordMode", "TimeSelectionPreRoll", "0", true)
reaper.SetExtState("luiza177_recordMode", "Normal", "0", true)
reaper.SetExtState("luiza177_recordMode", "Loop", "1", true)
reaper.SetToggleCommandState(scriptSection, scriptId, 1)
reaper.SetToggleCommandState(scriptSection, timeSelectionPreRoll, 0)
reaper.SetToggleCommandState(scriptSection, normal, 0)
reaper.RefreshToolbar2(scriptSection, scriptId)