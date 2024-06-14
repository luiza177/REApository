-- @author Luiza177
-- @noindex

-- USER AREA --------------------------------------------------------
local set_time_selection = true

-- FUNCTIONS --------------------------------------------------------
package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Functions')

-- -----------------------------------------------------------------------
function SmartNav_extend(direction)
  local undo_string = "Smart Nav: extend"
  local context = reaper.GetCursorContext()
  local cursorPos = reaper.GetCursorPosition()

  ------------------------------------------------- ENVELOPES
  if context == 2 then -- 0 if track panels, 1 if items, 2 if envelopes, otherwise unknown
    GetEnvelopePoints(cursorPos)
    undo_string = undo_string .. "selection to"
    if direction == "up" then
      undo_string = undo_string .. "previous envelope lane"
    elseif direction == "down" then
      undo_string = undo_string .. "next envelope lane"
    elseif direction == "forward" then
      reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_BRMOVEEDITTONEXTENVADDSELL"), 0) -- SWS/BR: Move edit cursor to next envelope point and add to selection
      undo_string = undo_string .. "next envelope point"
    elseif direction == "backward" then
      reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_BRMOVEEDITTOPEWVENVADDSELL"), 0) -- SWS/BR: Move edit cursor to previous envelope point and add to selection
      undo_string = undo_string .. "previous envelope point"
    else
    end
  else
  ------------------------------------------------- RAZOR EDITING
    local razor_editing = GetRazorEditStart()
    if razor_editing then
      undo_string = undo_string .. "Razor Edit "
      if direction == "up" then
        
      elseif direction == "down" then
        
      elseif direction == "forward" then
        
      elseif direction == "backward" then

      else
      end
      undo_string = undo_string .. direction
  ------------------------------------------------- TIME SELECTION
    else
      if direction == "up" then
        undo_string = undo_string .. "selection to "
        reaper.Main_OnCommand(40288, 0) -- Track: Go to previous track (leaving other tracks selected)
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX"), 0) -- Xenakios/SWS: Select items under edit cursor on selected tracks
        -- reaper.Main_OnCommand(40718, 0) --Item: Select all items on selected tracks in current time selection
        -- reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
        undo_string = undo_string .. "item in previous track"
      elseif direction == "down" then
        undo_string = undo_string .. "selection to "
        reaper.Main_OnCommand(40287, 0) -- Track: Go to next track (leaving other tracks selected)
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX"), 0) -- Xenakios/SWS: Select items under edit cursor on selected tracks
        -- reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
        -- reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
        undo_string = undo_string .. "item in next track"
      elseif direction == "forward" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_ADDRIGHTITEM"), 0) -- SWS: Add item(s) to right of selected item(s) to selection
        if set_time_selection then reaper.Main_OnCommand(40290, 0) end -- Time selection: Set time selection to items
        undo_string = undo_string .. "next item"
      elseif direction == "backward" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_ADDLEFTITEM"), 0) -- SWS: Add item(s) to left of selected item(s) to selection
        if set_time_selection then reaper.Main_OnCommand(40290, 0) end --Time selection: Set time selection to items
        undo_string = undo_string .. "previous item"
      else
      end
    end
  end
  return undo_string
end