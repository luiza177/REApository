-- @version 1.0
-- @noindex

reaper.Undo_BeginBlock()

local timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

if timeStart ~= timeEnd then
  local split = reaper.NamedCommandLookup("_S&M_SPLIT2")
  reaper.Main_OnCommand(split, 0)
-- else
end

--? Better way to do this?
reaper.Main_OnCommand(41924, 0)--Item: Nudge Items Volume -1dB
reaper.Main_OnCommand(41924, 0)--Item: Nudge Items Volume -1dB
reaper.Main_OnCommand(41924, 0)--Item: Nudge Items Volume -1dB
reaper.Main_OnCommand(41924, 0)--Item: Nudge Items Volume -1dB
--reaper.Main_OnCommand(41924, 0)--Item: Nudge Items Volume -1dB

reaper.Undo_EndBlock('-4dB at selection',0)
