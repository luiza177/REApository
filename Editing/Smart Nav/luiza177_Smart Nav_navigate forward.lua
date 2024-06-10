-- @author Luiza177
-- @about Select next media item in same track (and set time selection). Or move razor edit area forward without contents, or select next envelope point.
-- @noindex

reaper.Undo_BeginBlock()

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Smart Nav')

local undo_str = SmartNav("forward", false)

reaper.Undo_EndBlock(undo_str, 0)