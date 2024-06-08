-- @version 1.0
-- @noindex

reaper.Undo_BeginBlock()

-- function deletePT()
  -- local 
  local delete = reaper.NamedCommandLookup('_SWS_AWBUSDELETE')  
  reaper.Main_OnCommand(delete, 0)
  reaper.GetSet_LoopTimeRange(true, false, 0,0,false)
  reaper.Main_OnCommand(40289, 0) --Item: Unselect all items
-- end


-- rippleOn = reaper.GetToggleCommandState(1155)
-- if rippleOn == 1 then
--   rippleAll = reaper.GetToggleCommandState(40311) -- Set ripple editing all tracks
--   -- reaper.ShowConsoleMsg(rippleAll)
--   reaper.Main_OnCommand(40309, 0) -- Set ripple editing off
--   deletePT()
--   if rippleAll == 1 then
--     succ = reaper.SetToggleCommandState(0, 40311, 1) -- Set ripple editing all tracks
--     reaper.Main_OnCommand(0, 40311) -- Set ripple editing all tracks
--   else
--     succ = reaper.SetToggleCommandState(0, 40310, 1) -- Set ripple editing all tracks
--     reaper.Main_OnCommand(0, 40310) -- Set ripple editing per-track
--   end
--   reaper.ShowConsoleMsg(tostring(succ))

-- else
--   deletePT()
-- end

  
-- reaper.ShowConsoleMsg(rippleState)

reaper.Undo_EndBlock("Delete like PT (ignore Ripple)", 0)