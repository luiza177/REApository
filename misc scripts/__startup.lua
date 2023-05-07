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

function StartupScript_Archie()
    ARCHIE_INFO_COUNTER_TIME_PROJECT_AUTORUN_LUA=reaper.Main_OnCommand(reaper.NamedCommandLookup('_RSea6edc0e0d7e7441c62604c361905d60bb5036e8'),0)
end StartupScript_Archie()
