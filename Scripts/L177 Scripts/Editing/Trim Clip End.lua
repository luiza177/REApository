reaper.Undo_BeginBlock()

local timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

if timeStart == timeEnd then
  reaper.Main_OnCommand(41311,0)
else
  local cursorPos = reaper.GetCursorPosition()
  --move to time sel end
  reaper.Main_OnCommand(40631,0)
  reaper.Main_OnCommand(41311,0)
  reaper.SetEditCurPos(cursorPos, true, false)
end

reaper.Undo_EndBlock('Trim clip End',0)

