-- @description Smart Nav: extend selection down
-- @author Luiza177
-- @version 0.1
-- @about Add adjacent  media item in next track to selection. 
-- 
-- FUTURE: or extend razor edit area(s) forward. Or select nearest envelope point in next envelope lane.
-- @noindex
-- @changelog
--    - v0.1 - init

function GetRazorEditStart()
    local retval = false  
    -- local position = ""

    for i=0, reaper.CountTracks(0)-1 do
        _, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "string", false)
        if x ~= "" then 
            retval = true
            -- x = x:match "%d+.%d+"
            
            -- if position == "" then position = x
            -- elseif position > x then position = x
            -- end
        
        end
        
    end
    
    return retval--, position

end

reaper.Undo_BeginBlock()

-- context = reaper.GetCursorContext()

-- if context == 2 then -- 0 if track panels, 1 if items, 2 if envelopes, otherwise unknown
--     cursorPos = reaper.GetCursorPosition()
--     env = reaper.GetSelectedTrackEnvelope(0)

--     --if no point is selected
--     envPointId = reaper.GetEnvelopePointByTime(env, cursorPos)
--     -- TO BE CONTINUED
-- end

razor_editing = GetRazorEditStart()

if not razor_editing then
    -- cursorPos = reaper.GetCursorPosition()
    reaper.Main_OnCommand(40287, 0) --Track: Go to next track (leaving other tracks selected)
    local command = reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX")
    reaper.Main_OnCommand(command, 0) --Xenakios/SWS: Select items under edit cursor on selected tracks
    -- reaper.Main_OnCommand(40718, 0) --Item: Select all items on selected tracks in current time selection
    -- reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
else
    reaper.Main_OnCommand(42403, 0) --Razor edit: Move areas down without contents
    local command = reaper.NamedCommandLookup("_XENAKIOS_SELNEXTTRACK")
    reaper.Main_OnCommand(command, 0)
    -- TODO: Extend razor edit
end

reaper.Undo_EndBlock("Smart navigate down", 0)
