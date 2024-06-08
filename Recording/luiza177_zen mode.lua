-- @author Luiza177
-- @version 1.0
-- @noindex
-- @changelog
--    - v1.0 - init

-- if not reaper.HasExtState("ZenModeToggle", "toggleValue") then -- section, key
--     return
-- end

local scriptSection = ({reaper.get_action_context()})[3]
local scriptId = ({reaper.get_action_context()})[4]

local value = reaper.GetExtState("luiza177_zenRecording", "zenMode")
value = value == '1' and 0 or 1 -- if on, then off. if off then on

reaper.SetExtState("luiza177_zenRecording", "zenMode", value, true)
reaper.SetToggleCommandState(scriptSection, scriptId, value)
reaper.RefreshToolbar2(scriptSection, scriptId)