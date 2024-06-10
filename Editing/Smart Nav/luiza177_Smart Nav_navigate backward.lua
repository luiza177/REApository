-- @author Luiza177
-- @about Select previous media item in same track (and set time selection). Or move razor edit area back without contents, or select previous envelope point.
-- @noindex

reaper.Undo_BeginBlock()

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Smart Nav')

local undo_str = SmartNav("backward", false)

reaper.Undo_EndBlock(undo_str, 0)