reaper.Undo_BeginBlock()
local timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, 0,0,false)

if timeStart == timeEnd then
  reaper.Main_OnCommand(40102,0) --Time selection: Move cursor left, creating time selection
else
  reaper.Main_OnCommand(40037,0) --Time selection: Shift left (by time selection length)
end

reaper.Undo_EndBlock('Move cursor left, creating time selection', 0)

