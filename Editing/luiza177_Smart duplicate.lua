-- @description Smart Duplicate
-- @author Luiza177
-- @version 1.0
-- @about duplicates Item, selected part of item / razor edit  or Track depending on mouse context
-- @noindex
-- @changelog
--    - v1.0 - init

reaper.Undo_BeginBlock()

-- window, segment = reaper.BR_GetMouseCursorContext()
-- reaper.ShowConsoleMsg(window)
-- reaper.ShowConsoleMsg(segment)

local context = reaper.GetCursorContext2(true)
-- reaper.ShowConsoleMsg(context)
local undo_text = ""

if context == 1 then
  undo_text = "Item"
  
  local start, finish = reaper.GetSet_LoopTimeRange(false, false, 0, 0, true)
  if start ~= finish then
    reaper.Main_OnCommand(41296, 0) -- Item: Duplicate selected area of items
  else
    reaper.Main_OnCommand(41295, 0) -- Item: Duplicate items
  end
elseif context == 0 then
  undo_text = "Track"
  reaper.Main_OnCommand(40309, 0) -- Set ripple editing off
  reaper.Main_OnCommand(40062, 0) -- Track: Duplicate track
  reaper.Main_OnCommand(40421, 0) -- Item: Select all items in track
  reaper.Main_OnCommand(40006, 0) -- Item: Remove items
end

reaper.Undo_EndBlock(string.format("Smart Duplicate - %s", undo_text), 0)
