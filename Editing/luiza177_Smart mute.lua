-- @description Smart Mute
-- @author Luiza177
-- @version 1.0
-- @about Mutes items, selected part of items / razor edit or tracks, depending on context.
-- @changelog
--    - v1.0 - init

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

local context = reaper.GetCursorContext()
local timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, 0,0,false)
local razor_editing = GetRazorEditStart()

if context == 1 then --  0 if track panels, 1 if items, 2 if envelopes, otherwise unknown
    if timeStart ~= timeEnd or razor_editing then
        reaper.Main_OnCommand(40061, 0) -- Item: Split items at time selection
    end   
    reaper.Main_OnCommand(40175, 0) -- Item properties: Toggle mute
elseif context == 2 then
    reaper.Main_OnCommand(42211, 0) -- Envelope: Mute automation items
else
    reaper.Main_OnCommand(40280, 0) -- Track: Mute/unmute tracks
end

reaper.Undo_EndBlock('Smart mute', 0)
