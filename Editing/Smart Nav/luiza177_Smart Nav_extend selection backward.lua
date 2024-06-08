-- @description Smart Nav: Extend selection backward
-- @author Luiza177
-- @version 0.1
-- @about Add previous media item in same track to selection. 
-- 
-- FUTURE: or extend razor edit area(s) back (?), or add previous envelope point to selection.
-- @noindex
-- @changelog
--    - v0.1 - init

function GetStartOfRazorEdit(timeList)

    local words = {}
    for word in timeList:gmatch("%S+") do 
        table.insert(words, word) 
    end
    return words[1]
end


reaper.Undo_BeginBlock()

context = reaper.GetCursorContext()

-- if context == 2 then -- 0 if track panels, 1 if items, 2 if envelopes, otherwise unknown
--     cursorPos = reaper.GetCursorPosition()
--     env = reaper.GetSelectedTrackEnvelope(0)

--     --if no point is selected
--     envPointId = reaper.GetEnvelopePointByTime(env, cursorPos)
--     -- TO BE CONTINUED
-- end

track = reaper.GetSelectedTrack(0, 0)
_, stringNeedBig = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false) -- false = setNewValue

if stringNeedBig ~= "" then -- if RAZOR EDITING
    reaper.Main_OnCommand(42400, 0) --Razor edit: Move areas backwards without contents

    local _, newRazorEdit = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false) -- false = setNewValue
    reaper.SetEditCurPos(GetStartOfRazorEdit(newRazorEdit), true, false) --move view, seek play
    -- TODO: Add function for getting last razor edit area end
else
    command = reaper.NamedCommandLookup("_SWS_ADDLEFTITEM")
    reaper.Main_OnCommand(command, 0) --SWS: Add item(s) to left of selected item(s) to selection
    reaper.Main_OnCommand(40290, 0) --Time selection: Set time selection to items
end

reaper.Undo_EndBlock("Smart extend selection Forward", 0)

-- TODO: extend for all tracks