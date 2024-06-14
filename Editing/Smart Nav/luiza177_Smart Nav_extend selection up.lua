-- @author Luiza177
-- @about Add adjacent media item in previous track to selection. 
-- 
-- FUTURE: or extend razor edit area(s) up. Or select nearest envelope point in previous envelope lane.
-- @noindex

reaper.Undo_BeginBlock()

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Smart Nav_extend')

local undo_str = SmartNav("up")

reaper.Undo_EndBlock(undo_str, 0)