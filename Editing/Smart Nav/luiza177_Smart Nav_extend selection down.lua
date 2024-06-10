-- @author Luiza177
-- @about Add adjacent  media item in next track to selection. 
-- 
-- FUTURE: or extend razor edit area(s) forward. Or select nearest envelope point in next envelope lane.
-- @noindex

reaper.Undo_BeginBlock()

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Smart Nav')

local undo_str = SmartNav("down", true)

reaper.Undo_EndBlock(undo_str, 0)