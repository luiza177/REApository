-- @author Luiza177
-- @version 1.0
-- @noindex
-- @changelog
--    - v1.0 - init

function Wait(seconds)
    actionCalled = reaper.time_precise()
    while (reaper.time_precise() < actionCalled + seconds) do
        -- reaper.ShowConsoleMsg(tostring(reaper.time_precise()))
    end
end

reaper.Undo_BeginBlock()

waitTime = 3


isNewValue, _, sec, cmd = reaper.get_action_context()
-- state = reaper.GetToggleCommandStateEx(sec, cmd)
zenStopCmdID = reaper.NamedCommandLookup("_RSa2fe9299e2fca445e8ffa0067530bfe509d9d7ba")
-- reaper.SetExtState("luiza177_zenRecording", "stop", "0", true)
reaper.SetToggleCommandState(sec, zenStopCmdID, "0")


recording = reaper.GetToggleCommandState(1013) -- Transport: Record
playing = reaper.GetToggleCommandState(1007) -- Transport: Play
zen = reaper.GetExtState("luiza177_zenRecording", "zenMode")

zenPlayCmdID = reaper.NamedCommandLookup("")
reaper.SetToggleCommandState(sec, zenPlayCmdID, playing)

reaper.SetExtState("luiza177_zenRecording", "recording", "1", true)
reaper.SetToggleCommandState(sec, cmd, "1")
reaper.RefreshToolbar2(sec, cmd)

if recording == 1 then
    -- auto retake
    if zen == "1" then
        reaper.defer(Wait(waitTime))
    end
    -- reaper.ShowConsoleMsg("recording")
    reaper.Main_OnCommand(40668, 0) -- Transport: Stop (DELETE all record media)
    reaper.Main_OnCommand(1013, 0) -- Transport: Record
elseif playing == 1 then
    -- start recording
    -- reaper.ShowConsoleMsg("playing")
    reaper.Main_OnCommand(1013, 0) -- Transport: Record
else
    -- wait 3 seconds, then record
    -- reaper.ShowConsoleMsg("stopped")
    if zen == "1" then
        reaper.defer(Wait(waitTime))
    end
    reaper.Main_OnCommand(1013, 0) -- Transport: Record
end

reaper.Undo_EndBlock("Zen record - auto retake", 0)