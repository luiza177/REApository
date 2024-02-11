function GetRazorEditStart()
    local retval = false  
    local position = ""
    for i=0, reaper.CountTracks(0)-1 do
        _, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "string", false)
        if x ~= "" then 
            retval = true        
            x = x:match "%d+.%d+"
            position = x
            -- if position == "" then position = x
            -- elseif position > x then position = x
            -- end
        end
        
    end
    
    return retval, position
end

reaper.Undo_BeginBlock()

------------------------------------------------- ENVELOPES
context = reaper.GetCursorContext()

if context == 2 then -- 0 if track panels, 1 if items, 2 if envelopes, otherwise unknown
    cursorPos = reaper.GetCursorPosition()
    env = reaper.GetSelectedTrackEnvelope(0)

    --if no point is selected
    envPointId = reaper.GetEnvelopePointByTime(env, cursorPos)
    -- TO BE CONTINUED
end
-------------------------------------------------

------------------------------------------------- RAZOR OR TIME SEL 
razor_editing = GetRazorEditStart()

if not razor_editing then
    -- TODO: Without changing track selection?
    reaper.Main_OnCommand(40417, 0) --Item navigation: Select and move to next item
    reaper.Main_OnCommand(40290, 0) --Time selection: Set time selection to items
else
    reaper.Main_OnCommand(42399, 0) --Razor edit: Move areas forwards without contents
    _, position = GetRazorEditStart()
    reaper.SetEditCurPos( position, true, false )
end

reaper.Undo_EndBlock("SmartNav: Forward", 0)