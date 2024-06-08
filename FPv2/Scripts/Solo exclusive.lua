-- @version 1.0
-- @noindex
-- @changelog
--    - v1.0 - init

reaper.Undo_BeginBlock()
reaper.Main_OnCommand(40340, 0) --Track: Unsolo all tracks
reaper.Main_OnCommand(40728, 0) --Track: Solo tracks
reaper.Undo_EndBlock("Solo exclusive selected tracks", 0)