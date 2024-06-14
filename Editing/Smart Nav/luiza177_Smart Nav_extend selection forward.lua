-- @author Luiza177
-- @about Add next media item in same track to selection. 
-- 
-- FUTURE: or extend razor edit area(s) forward, or add next envelope point to selection.
-- @noindex

reaper.Undo_BeginBlock()

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Smart Nav_extend')

local undo_str = SmartNav_extend("forward")

reaper.Undo_EndBlock(undo_str, 0)