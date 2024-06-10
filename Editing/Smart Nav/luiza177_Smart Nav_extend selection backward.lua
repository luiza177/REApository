-- @author Luiza177
-- @about Add previous media item in same track to selection. 
-- 
-- FUTURE: or extend razor edit area(s) back (?), or add previous envelope point to selection.
-- @noindex

reaper.Undo_BeginBlock()

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Smart Nav')

local undo_str = SmartNav("backward", true)

reaper.Undo_EndBlock(undo_str, 0)
