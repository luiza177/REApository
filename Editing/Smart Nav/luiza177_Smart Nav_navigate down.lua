-- @description Smart Nav: Navigate down
-- @author Luiza177
-- @version 1.0
-- @about Select adjacent media item in next track. Or move razor edit area down without contents.
-- 
-- FUTURE: or select nearest envelope point in next envelope lane
-- @changelog
--    - v1.0 - init
-- @noindex

function GetRazorEditStart()
    local retval = false  
    for i=0, reaper.CountTracks(0)-1 do
        _, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "string", false)
        if x ~= "" then 
            retval = true
            -- x = x:match "%d+.%d+"
            -- reaper.ShowConsoleMsg(x)
            -- if position == "" then position = x
            -- elseif position > x then position = x
            -- end
        
        end
        
    end
    
    return retval--, position
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
-------------------------------------------------

------------------------------------------------- RAZOR OR TIME SEL 
razor_editing = GetRazorEditStart()

if not razor_editing then
    cursorPos = reaper.GetCursorPosition()
    reaper.Main_OnCommand(40419, 0) --Item navigation: Select and move to item in next track
    reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
else
    reaper.Main_OnCommand(42403, 0) --Razor edit: Move areas down without contents
    command = reaper.NamedCommandLookup("_XENAKIOS_SELNEXTTRACK")
    reaper.Main_OnCommand(command, 0)
end

reaper.Undo_EndBlock("SmartNav: Down", 0)
