-- @version 1.0
-- @noindex
-- @changelog
--    - v1.0 - init

-- bool is_new_value, str filename_with_path, int sectionID, int cmdID, int mode, int resolution, int val, str contextstr = reaper.get_action_context()
local isNewValue, file, sec, cmd = reaper.get_action_context()
-- local state = reaper.GetToggleCommandStateEx(sec, cmd);
reaper.SetToggleCommandState(sec, cmd, 0)
reaper.RefreshToolbar2(sec, cmd)
