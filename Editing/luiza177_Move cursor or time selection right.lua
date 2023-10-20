reaper.Undo_BeginBlock()
local timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, 0,0,false)

if timeStart == timeEnd then
  reaper.Main_OnCommand(40103,0) --Time selection: Move cursor right, creating time selection
else
  reaper.Main_OnCommand(40038,0) --Time selection: Shift right (by time selection length)
end

reaper.Undo_EndBlock('Move cursor left, creating time selection', 0)

