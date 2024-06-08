-- @version 1.0
-- @noindex
-- @changelog
--    - v1.0 - init

local _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context() 

if mouse_scroll > 0  then 
    reaper.Main_OnCommand(40838, 0) --Move edit cursor to start of current measure (no seek)
elseif mouse_scroll < 0 then 
    reaper.Main_OnCommand(40837, 0) --Move edit cursor to start of next measure (no seek)
end