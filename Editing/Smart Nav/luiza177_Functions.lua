-- @no-index

-- ----------------------------------------------------------- ENVELOPES
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

local function getSelectedEnvelopePoints(envPoints)
  local selectedEnvPoints = {}
  local j = 1
  for i = 1, #envPoints do
    if envPoints[i].selected == true then
      selectedEnvPoints[j] = {
        time = envPoints[i].time,
        value = envPoints[i].value,
        shape = envPoints[i].shape,
        tension = envPoints[i].tension,
        selected = envPoints[i].selected,
        index = i
      }
      j = j + 1
    end
  end
  return selectedEnvPoints
end

function GetEnvelopePoints(selectedEnvelope, cursorPos)
  local numEnvelopePoints = reaper.CountEnvelopePoints(selectedEnvelope)
  local envPoints = {}
  local anySelected = false
  for i=0, numEnvelopePoints-1 do
    local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(reaper.GetSelectedEnvelope(0), i)
    if retval then
      envPoints[i] = {
        time = time,
        value = value,
        shape = shape,
        tension = tension,
        selected = selected
      }
      if selected then
        anySelected = true
      end
    end
  end
  if not anySelected then
    local closestToCursor = reaper.GetEnvelopePointByTime(selectedEnvelope, findClosestEnvelopePoint(envPoints, cursorPos))
    reaper.SetEnvelopePoint(selectedEnvelope, closestToCursor, _, _, _, _, true, false) -- set selected
    envPoints[closestToCursor].selected = true
  end
  return envPoints
end

function ExtendEnvelopePointsSelection(selectedEnvelope, cursorPos, forwardOrBackward)
  local envPoints = GetEnvelopePoints(selectedEnvelope, cursorPos)
  local selectedEnvPoints = getSelectedEnvelopePoints(envPoints)
  local first = selectedEnvPoints[1]
  local last = selectedEnvPoints[#selectedEnvPoints]
  if forwardOrBackward ~= nil then
    if forwardOrBackward > 0 then
      reaper.SetEnvelopePoint(selectedEnvelope, last.index + forwardOrBackward, _, _, _, _, true, false) -- set selected
    else
      reaper.SetEnvelopePoint(selectedEnvelope, first.index + forwardOrBackward, _, _, _, _, true, false) -- set selected
    end
  end
end

function GoToNextOrPreviousEnvelope(cursorPos)
  local selectedEnvelope = reaper.GetSelectedEnvelope(0)
  GetEnvelopePoints(selectedEnvelope, cursorPos)
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


