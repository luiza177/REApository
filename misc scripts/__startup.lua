-- @author Luiza177
-- @version 1.0
-- @noindex
-- @changelog
--    - v1.0 - init

-- Start script: Adaptive grid (background process)
local adaptive_grid_cmd = '_RS6a4ecd962e6101f6f55408dd535c25addd8de2e0'
reaper.Main_OnCommand(reaper.NamedCommandLookup(adaptive_grid_cmd), 0)

-- LOAD SmartRecord / ZEN states
section = ({reaper.get_action_context()})[3]
zenCmdID = reaper.NamedCommandLookup("_RS359bd63916bb3ef4ca5503166d76dea7b6992a80")
zenValue = reaper.GetExtState("luiza177_zenRecording", "zenMode")
reaper.SetToggleCommandState(section, zenCmdID, zenValue)

zenStopCmdID = reaper.NamedCommandLookup("_RSa2fe9299e2fca445e8ffa0067530bfe509d9d7ba")
zenStopValue = reaper.GetExtState("luiza177_zenRecording", "stop")
reaper.SetToggleCommandState(section, zenStopCmdID, zenStopValue)

-- zenRecordCmdID
-- zenPlayCmdID

-- LOAD Record Mode states
recModeTimeSelCmdId = reaper.NamedCommandLookup("_RS39bc6a78cca723e8c317548b1d724f540187c51b")
recModeNormalCmdId = reaper.NamedCommandLookup("_RSb1fc8a95e1a9d49d2f2c8832418adab7389678f9")
recModeLoopCmdId = reaper.NamedCommandLookup("_RS39bc6a78cca723e8c317548b1d724f540187c51b")
local recModeTimeSelValue = reaper.GetExtState("luiza177_recordMode", "TimeSelectionPreRoll")
local recModeNormalValue = reaper.GetExtState("luiza177_recordMode", "Normal")
local recModeLoopValue = reaper.GetExtState("luiza177_recordMode", "Loop")

reaper.SetToggleCommandState(section, recModeTimeSelCmdId, recModeTimeSelValue)
reaper.SetToggleCommandState(section, recModeNormalCmdId, recModeNormalValue)
reaper.SetToggleCommandState(section, recModeLoopCmdId, recModeLoopValue)

-- ARCHIE
function StartupScript_Archie()
    -- ARCHIE_INFO_COUNTER_TIME_PROJECT_AUTORUN_LUA=reaper.Main_OnCommand(reaper.NamedCommandLookup('_RSea6edc0e0d7e7441c62604c361905d60bb5036e8'),0)
end StartupScript_Archie()

-- MASTERING EXPLAINED
-- package.path = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]])
-- 	.. "MasteringExplained_StarterPack/?.lua;"
-- 	.. package.path
-- require("lib/rmsp").Startup()