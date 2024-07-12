-- @description Smart Nav: arrow key project navigation
-- @author Luiza177
-- @version 0.0.1
-- @about
-- #Smart Nav
-- Context Navigate adjacent media items or envelope points, or move razor edit areas using the arrow keys like you would in Cubase/Nuendo or Studio One.
-- FUTURE: 
-- - While holding shift (or your choice of modifier) add items to selection or extend razor edit areas.
-- - Select nearest envelope point in adjacent envelope lanes.
-- @changelog
--   First release.
-- @provides
-- [nomain] .
-- [nomain] luiza177_Smart Nav_extend.lua
-- [nomain] luiza177_Functions.lua
-- [main] luiza177_Smart Nav_navigate up.lua
-- [main] luiza177_Smart Nav_navigate down.lua
-- [main] luiza177_Smart Nav_navigate backward.lua
-- [main] luiza177_Smart Nav_navigate forward.lua
-- [main] luiza177_Smart Nav_extend selection up.lua
-- [main] luiza177_Smart Nav_extend selection down.lua
-- [main] luiza177_Smart Nav_extend selection backward.lua
-- [main] luiza177_Smart Nav_extend selection forward.lua

-- ------------------------------------------------------------------

-- USER AREA --------------------------------------------------------
local set_time_selection = false

-- FUNCTIONS --------------------------------------------------------
package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Functions')

-- -----------------------------------------------------------------------
function SmartNav(direction)
  local undo_string = "Smart Nav: "
  local context = reaper.GetCursorContext()
  local cursorPos = reaper.GetCursorPosition()

  ------------------------------------------------- ENVELOPES
  if context == 2 then -- 0 if track panels, 1 if items, 2 if envelopes, otherwise unknown
    local selectedEnvelope = reaper.GetSelectedEnvelope(0)
    GetEnvelopePoints(selectedEnvelope, cursorPos)
    undo_string = undo_string .. "selection to"
    if direction == "up" then
      reaper.Main_OnCommand(41180, 0) -- Envelopes: Move selected points up a little bit
      undo_string = "Envelopes: Move selected points up a little bit"
    elseif direction == "down" then
      reaper.Main_OnCommand(41181, 0) -- Envelopes: Move selected points down a little bit
      undo_string = "Envelopes: Move selected points down a little bit"
    elseif direction == "forward" then
      reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_ENV_SEL_NEXT_POINT"), 0) -- SWS/BR: Select next envelope point
      undo_string = undo_string .. "next envelope point"
    elseif direction == "backward" then
      reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_ENV_SEL_PREV_POINT"), 0) -- SWS/BR: Select previous envelope point
      undo_string = undo_string .. "previous envelope point"
    else
    end
  else
  ------------------------------------------------- RAZOR EDITING
    local razor_editing = GetRazorEditStart()
    if razor_editing then
      undo_string = undo_string .. "Razor Edit "
      if direction == "up" then
        -- TODO : select new track
        reaper.Main_OnCommand(42402, 0) -- Razor edit: Move areas up without contents
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELPREVTRACK"), 0)
      elseif direction == "down" then
        reaper.Main_OnCommand(42403, 0) -- Razor edit: Move areas down without contents
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELNEXTTRACK"), 0)
      elseif direction == "forward" then
        reaper.Main_OnCommand(42399, 0) -- Razor edit: Move areas forwards without contents
        local _, razor_edit_position = GetRazorEditStart()
        reaper.SetEditCurPos(razor_edit_position, true, false ) -- pos, moveView, seekPlay 
      elseif direction == "backward" then
        reaper.Main_OnCommand(42400, 0) -- Razor edit: Move areas backwards without contents
        local _, razor_edit_position = GetRazorEditStart()
        reaper.SetEditCurPos(razor_edit_position, true, false ) -- pos, moveView, seekPlay 
      else
      end
      undo_string = undo_string .. direction
  ------------------------------------------------- TIME SELECTION
    else
      if direction == "up" then
          reaper.Main_OnCommand(40418, 0) -- Item navigation: Select and move to item in previous track
          reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
        undo_string = undo_string .. "item in previous track"
      elseif direction == "down" then
          reaper.Main_OnCommand(40419, 0) -- Item navigation: Select and move to item in next track
          reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
        undo_string = undo_string .. "item in next track"
      elseif direction == "forward" then
          reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        if set_time_selection then reaper.Main_OnCommand(40290, 0) end -- Time selection: Set time selection to items
        undo_string = undo_string .. "next item"
      elseif direction == "backward" then
          reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
        if set_time_selection then reaper.Main_OnCommand(40290, 0) end --Time selection: Set time selection to items
        undo_string = undo_string .. "previous item"
      else
      end
    end
  end
  return undo_string
end