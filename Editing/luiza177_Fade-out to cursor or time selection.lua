reaper.Undo_BeginBlock()

local timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local cursorPos = reaper.GetCursorPosition()

if timeStart == timeEnd or not cursorPos == timeStart then
  reaper.Main_OnCommand(40510,0) --Fade items out from cursor
else
  reaper.Main_OnCommand(40631,0) --Move cursor to end of time selection
  reaper.Main_OnCommand(40510,0) --Fade items out from cursor
  reaper.SetEditCurPos(cursorPos, true, false)
end

reaper.Undo_EndBlock('Fade-out from cursor/time selection',0)

--if timeEnd maior ou igual clip end, default to cursor position
