-- @description Smart Nav: Navigate up
-- @author Luiza177
-- @version 1.0
-- @about Select adjacent media item in previous track. Or move razor edit area up without contents. 
-- 
-- FUTURE: or select nearest envelope point in previous envelope lane
-- @changelog
--    - v1.0 - init

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

------------------------------------------------- ENVELOPES
-- context = reaper.GetCursorContext()

-- if context == 2 then -- 0 if track panels, 1 if items, 2 if envelopes, otherwise unknown
--     cursorPos = reaper.GetCursorPosition()
--     env = reaper.GetSelectedTrackEnvelope(0)

--     --if no point is selected
--     envPointId = reaper.GetEnvelopePointByTime(env, cursorPos)
--     -- TO BE CONTINUED
-- end

razor_editing = GetRazorEditStart()
-------------------------------------------------

------------------------------------------------- RAZOR OR TIME SEL 
if not razor_editing then
    cursorPos = reaper.GetCursorPosition()
    reaper.Main_OnCommand(40418, 0) --Item navigation: Select and move to item in previous track
    reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play

else
    -- TODO : select new track
    reaper.Main_OnCommand(42402, 0) --Razor edit: Move areas up without contents
    command = reaper.NamedCommandLookup("_XENAKIOS_SELPREVTRACK")
    reaper.Main_OnCommand(command, 0)
end

reaper.Undo_EndBlock("SmartNav: Up", 0)
