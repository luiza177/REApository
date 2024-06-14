-- @author Luiza177
-- @about Select adjacent media item in next track. Or move razor edit area down without contents.
-- 
-- FUTURE: or select nearest envelope point in next envelope lane
-- @noindex

reaper.Undo_BeginBlock()

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Smart Nav')

local undo_str = SmartNav("down")

reaper.Undo_EndBlock(undo_str, 0)
