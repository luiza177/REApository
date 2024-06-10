-- @description Smart Nav: arrow key project navigation
-- @author Luiza177
-- @version 0.0.1
-- @about
-- #Smart Nav
-- Context Navigate adjacent media items or envelope points, or move razor edit areas using the arrow keys like you would in Cubase/Nuendo or Studio One.
-- FUTURE: 
-- - While holding shift (or your choice of modifier) add items to selection or extend razor edit areas.
-- - Select nearest envelope point in adjacent envelope lanes.
-- @provides
-- [nomain] .
-- [nomain] luiza177_Smart Nav_extend.lua
-- [main] luiza177_Smart Nav_navigate up.lua
-- [main] luiza177_Smart Nav_navigate down.lua
-- [main] luiza177_Smart Nav_navigate backward.lua
-- [main] luiza177_Smart Nav_navigate forward.lua
-- [main] luiza177_Smart Nav_extend selection up.lua
-- [main] luiza177_Smart Nav_extend selection down.lua
-- [main] luiza177_Smart Nav_extend selection backward.lua
-- [main] luiza177_Smart Nav_extend selection forward.lua
-- @changelog
--   First release.

-- @noindex

-- TODO: separate Navigate and Extend

-- USER AREA --------------------------------------------------------
local set_time_selection = true

-- FUNCTIONS --------------------------------------------------------
local function getRazorEditStart()
  local retval = false
  local position;
  for i=0, reaper.CountTracks(0)-1 do
    local _, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "string", false)
    if x ~= "" then
      retval = true
      position = tonumber(x:match('[^%s]+'))
      -- if position == "" then position = x
      -- elseif position > x then position = x
      -- end
    end
  end
  return retval, position

end

local function getEnvelopePoints(cursorPos)
  local selectedEnvelope = reaper.GetSelectedEnvelope(0)
  local numEnvelopePoints = reaper.CountEnvelopePoints(selectedEnvelope)
  for i=0, numEnvelopePoints-1 do
    local retval, time, value, shape, tension, selected= reaper.GetEnvelopePoint(reaper.GetSelectedEnvelope(0), i)
    -- create array of envelope points selected or not
    -- check if none are selected, if so, select closest to cursor or selected point in previous/next envelope
    -- find first and last selected
    -- depending on operation, decide SetEnvelopePoint
    reaper.ShowConsoleMsg(i..": "..time.." - "..value.." ("..tension..") "..tostring(selected).."\n")
  end
  reaper.ShowConsoleMsg(reaper.GetEnvelopePointByTime(selectedEnvelope, cursorPos).."\n")
end
-----------------------------------------------------------------------

function SmartNav(direction, extendSelection)
  local undo_string = "Smart Nav: "
  if extendSelection then undo_string = undo_string.."extend " end
  local context = reaper.GetCursorContext()
  local cursorPos = reaper.GetCursorPosition()

  ------------------------------------------------- ENVELOPES
  if context == 2 then -- 0 if track panels, 1 if items, 2 if envelopes, otherwise unknown
    getEnvelopePoints(cursorPos)
    undo_string = undo_string .. "selection to"
    if direction == "up" then
      -- if extendSelection then
      -- else
      -- end
      reaper.Main_OnCommand(41863, 0) -- Track: Select previous envelope
      undo_string = undo_string .. "previous envelope lane"
    elseif direction == "down" then
      -- if extendSelection then
      -- else
      -- end
      reaper.Main_OnCommand(41864, 0) -- Track: Select next envelope
      undo_string = undo_string .. "next envelope lane"
    elseif direction == "forward" then
      if extendSelection then
        -- move cursor to selected envelope point
-- TODO
        -- move cursor to next env point adding to selection
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_BRMOVEEDITTONEXTENVADDSELL"), 0) -- SWS/BR: Move edit cursor to next envelope point and add to selection
        -- reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
      else
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_ENV_SEL_NEXT_POINT"), 0) -- SWS/BR: Select next envelope point
      end
      undo_string = undo_string .. "next envelope point"
    elseif direction == "backward" then
      if extendSelection then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_BRMOVEEDITTOPEWVENVADDSELL"), 0) -- SWS/BR: Move edit cursor to previous envelope point and add to selection
        -- reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
      else
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_ENV_SEL_PREV_POINT"), 0) -- SWS/BR: Select previous envelope point
      end
      undo_string = undo_string .. "previous envelope point"
    else
    end
  else
  ------------------------------------------------- RAZOR EDITING
    local razor_editing = getRazorEditStart()
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
        local _, razor_edit_position = getRazorEditStart()
        reaper.SetEditCurPos(razor_edit_position, true, false ) -- pos, moveView, seekPlay 
      elseif direction == "backward" then
        reaper.Main_OnCommand(42400, 0) -- Razor edit: Move areas backwards without contents
        local _, razor_edit_position = getRazorEditStart()
        reaper.SetEditCurPos(razor_edit_position, true, false ) -- pos, moveView, seekPlay 
      else
      end
      undo_string = undo_string .. direction
  ------------------------------------------------- TIME SELECTION
    else
      if direction == "up" then
        if extendSelection then
          undo_string = undo_string .. "selection to "
          reaper.Main_OnCommand(40288, 0) -- Track: Go to previous track (leaving other tracks selected)
          reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX"), 0) -- Xenakios/SWS: Select items under edit cursor on selected tracks
          -- reaper.Main_OnCommand(40718, 0) --Item: Select all items on selected tracks in current time selection
          -- reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
        else
          reaper.Main_OnCommand(40418, 0) -- Item navigation: Select and move to item in previous track
          reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
        end
        undo_string = undo_string .. "item in previous track"
      elseif direction == "down" then
        if extendSelection then
          undo_string = undo_string .. "selection to "
          reaper.Main_OnCommand(40287, 0) -- Track: Go to next track (leaving other tracks selected)
          reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX"), 0) -- Xenakios/SWS: Select items under edit cursor on selected tracks
          -- reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
          -- reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
        else
          reaper.Main_OnCommand(40419, 0) -- Item navigation: Select and move to item in next track
          reaper.SetEditCurPos(cursorPos, true, false ) --move view, seek play
        end
        undo_string = undo_string .. "item in next track"
      elseif direction == "forward" then
        if extendSelection then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_ADDRIGHTITEM"), 0) -- SWS: Add item(s) to right of selected item(s) to selection
        else
          reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        end
        if set_time_selection then reaper.Main_OnCommand(40290, 0) end -- Time selection: Set time selection to items
        undo_string = undo_string .. "next item"
      elseif direction == "backward" then
        if extendSelection then 
          reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_ADDLEFTITEM"), 0) -- SWS: Add item(s) to left of selected item(s) to selection
        else
          reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
        end
        if set_time_selection then reaper.Main_OnCommand(40290, 0) end --Time selection: Set time selection to items
        undo_string = undo_string .. "previous item"
      else
      end
    end
  end
  return undo_string
end