-- @description Smart Nav: Extend selection up
-- @author Luiza177
-- @version 0.1
-- @about Add adjacent media item in previous track to selection. 
-- 
-- FUTURE: or extend razor edit area(s) up. Or select nearest envelope point in previous envelope lane.
-- @noindex
-- @changelog
--    - v0.1 - init
-- @noindex

function GetRazorEditStart()
    local retval = false  
    for i=0, reaper.CountTracks(0)-1 do
        _, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "", false)
        if x ~= "" then 
            retval = true        
        end
        
    end
    
    return retval

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
    reaper.Main_OnCommand(40288, 0) --Track: Go to previous track (leaving other tracks selected)
    local command = reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX")
    reaper.Main_OnCommand(command, 0) --Xenakios/SWS: Select items under edit cursor on selected tracks
    -- reaper.Main_OnCommand(40718, 0) --Item: Select all items on selected tracks in current time selection

else
    reaper.Main_OnCommand(42402, 0) --Razor edit: Move areas up without contents
    command = reaper.NamedCommandLookup("_XENAKIOS_SELPREVTRACK")
    reaper.Main_OnCommand(command, 0)
    -- TODO: Extend razor edit
end

reaper.Undo_EndBlock("Smart navigate up", 0)
