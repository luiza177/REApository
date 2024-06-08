-- @description Smart Nav: extend selection forward
-- @author Luiza177
-- @version 0.1
-- @about Add next media item in same track to selection. 
-- 
-- FUTURE: or extend razor edit area(s) forward, or add next envelope point to selection.
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
    reaper.Main_OnCommand(42399, 0) --Razor edit: Move areas forwards without contents

    -- TODO:
else
    command = reaper.NamedCommandLookup("_SWS_ADDRIGHTITEM")
    reaper.Main_OnCommand(command, 0) --SWS: Add item(s) to right of selected item(s) to selection
    reaper.Main_OnCommand(40290, 0) --Time selection: Set time selection to items
end

reaper.Undo_EndBlock("Smart extend selection Forward", 0)

-- TODO: extend for all tracks