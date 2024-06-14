-- @no-index

-- ----------------------------------------------------------- ENVELOPES
-- function ClearEnvelopeSelection()
--   local selectedEnvelope = reaper.GetSelectedEnvelope(0)
--   local numEnvelopePoints = reaper.CountEnvelopePoints(selectedEnvelope)
--   for i=0, numEnvelopePoints-1 do
--     local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(selectedEnvelope, i)
--     if retval then reaper.SetEnvelopePoint(selectedEnvelope, i, time, value, shape, tension, false) end
--   end
-- end

local function findClosestEnvelopePoint(envPoints, target)
  local closest = envPoints[0].time
  local minDifference = math.abs(closest - target)

  for i = 1, #envPoints do
    if envPoints[i] then
      local currentDifference = math.abs(envPoints[i].time - target)
      if currentDifference < minDifference then
        minDifference = currentDifference
        closest = envPoints[i].time
      end
    end
  end

  return closest
end

function GetEnvelopePoints(cursorPos)
  local selectedEnvelope = reaper.GetSelectedEnvelope(0)
  local numEnvelopePoints = reaper.CountEnvelopePoints(selectedEnvelope)
  local envPoints = {}
  for i=0, numEnvelopePoints-1 do
    local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(reaper.GetSelectedEnvelope(0), i)
    -- create array of envelope points selected or not
    if retval then
      envPoints[i] = {
        time = time,
        value = value,
        shape = shape,
        tension = tension,
        selected = selected
      }
    end
    -- check if none are selected, if so, select closest to cursor or selected point in previous/next envelope
    -- find first and last selected
    -- depending on operation, decide SetEnvelopePoint
    reaper.ShowConsoleMsg(i..": "..time.." - "..value.." ("..tension..") "..tostring(selected).."\n")
  end
  reaper.ShowConsoleMsg("before Cursor env point: "..reaper.GetEnvelopePointByTime(selectedEnvelope, cursorPos).."\n")
  reaper.ShowConsoleMsg("cursor pos: "..cursorPos.."\n")
  reaper.ShowConsoleMsg("Closest env point: "..reaper.GetEnvelopePointByTime(selectedEnvelope, findClosestEnvelopePoint(envPoints, cursorPos)).."\n")
end

----------------------------------------------------------- RAZOR EDIT
function GetRazorEditStart()
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
      -- TODO: create array of start and end positions
    end
  end
  return retval, position
end


