-- @description Extend time selection by one measure
-- @author Luiza177
-- @version 1.0
-- @changelog
--    - v1.0 - init

local start_sel, end_local = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local cursor = reaper.GetCursorPosition()

reaper.PreventUIRefresh(1)

if start_sel == 0 then
    reaper.GetSet_LoopTimeRange(true, false, cursor, cursor, false)
end

-- go to time selection end
reaper.Main_OnCommand(40631, 0) -- Go to end of time selection
-- go to next measure
reaper.Main_OnCommand(40837, 0) -- Move edit cursor to start of next measure (no seek)
-- set time selection end
reaper.Main_OnCommand(40626, 0) -- Time selection: Set end point
-- go back to og cursor
reaper.SetEditCurPos(cursor, false, false)

reaper.PreventUIRefresh(-1)