function GetStartOfRazorEdit(timeList)

    local words = {}
    for word in timeList:gmatch("%S+") do 
        table.insert(words, word) 
    end
    return words[1]
end


reaper.Undo_BeginBlock()

context = reaper.GetCursorContext()

if context == 2 then -- 0 if track panels, 1 if items, 2 if envelopes, otherwise unknown
    cursorPos = reaper.GetCursorPosition()
    env = reaper.GetSelectedTrackEnvelope(0)

    --if no point is selected
    envPointId = reaper.GetEnvelopePointByTime(env, cursorPos)
    -- TO BE CONTINUED
end

track = reaper.GetSelectedTrack(0, 0)
_, stringNeedBig = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false) -- false = setNewValue

if stringNeedBig ~= "" then -- if RAZOR EDITING
    reaper.Main_OnCommand(42400, 0) --Razor edit: Move areas backwards without contents

    local _, newRazorEdit = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false) -- false = setNewValue
    reaper.SetEditCurPos(GetStartOfRazorEdit(newRazorEdit), true, false) --move view, seek play
else
    reaper.Main_OnCommand(40416, 0) --Item navigation: Select and move to previous item
    reaper.Main_OnCommand(40290, 0) --Time selection: Set time selection to items
end

reaper.Undo_EndBlock("Smart Navigate Forward", 0)