-- @author Luiza177
-- @about Add adjacent  media item in next track to selection. 
-- 
-- FUTURE: or extend razor edit area(s) forward. Or select nearest envelope point in next envelope lane.
-- @noindex

reaper.Undo_BeginBlock()

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Smart Nav_extend')

local undo_str = SmartNav_extend("down")

reaper.Undo_EndBlock(undo_str, 0)