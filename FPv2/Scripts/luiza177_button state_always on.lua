-- bool is_new_value, str filename_with_path, int sectionID, int cmdID, int mode, int resolution, int val, str contextstr = reaper.get_action_context()
isNewValue, file, sec, cmd = reaper.get_action_context()
state = reaper.GetToggleCommandStateEx(sec, cmd);
reaper.SetToggleCommandState(sec, cmd, 1)
reaper.RefreshToolbar2(sec, cmd)
