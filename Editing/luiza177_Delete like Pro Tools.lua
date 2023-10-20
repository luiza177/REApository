reaper.Undo_BeginBlock()


delete = reaper.NamedCommandLookup('_SWS_AWBUSDELETE')  
reaper.Main_OnCommand(delete, 0)

-- rippleState = reaper.GetToggleCommandState(1155)

-- if rippleState then
  reaper.GetSet_LoopTimeRange(true, false, 0,0,false)
-- end
reaper.Main_OnCommand(40289, 0) --Item: Unselect all items

reaper.Undo_EndBlock("Delete like PT", 0)

--? apply to groups
