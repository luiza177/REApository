-- @description Transpose notes down to next visible note in Custom Note Order mode
-- @author Luiza177
-- @version 0.1
-- @about Transpose MIDI notes down to next visible note in Custom Note Order view (or just transpose notes down by a semitone)
-- @changelog
--    - v0.1 - init

local function findNoteinCustomNames(num, customNoteNames)
    for i = 1, #customNoteNames do
        if (customNoteNames[i] == num) then
            return i
        end
    end
    return -1
end

local track = reaper.GetSelectedTrack(0, 0)
local retval, trackStateChunk = reaper.GetTrackStateChunk(track, "", false)
if (not retval) then
    reaper.ShowConsoleMsg("Could not get Track state chunk")
    return
end

-- get custom note order
local customNoteOrder = {}
for notes in trackStateChunk:gmatch('CUSTOM_NOTE_ORDER(.-)\n') do
    -- reaper.ShowConsoleMsg("'"..thing.."'" .. "\n")
    for num in notes:gmatch("%S+") do
        customNoteOrder[#customNoteOrder+1] = tonumber(num) -- needs to be +1 ??
    end
end

local midiEditor = reaper.MIDIEditor_GetActive()

-- if no custom note order then just normal transpose
if (#customNoteOrder == 0) then
    reaper.MIDIEditor_OnCommand(midiEditor, 40178) --Edit: Move notes down one semitone
    return
end

-- get selected note number
local take = reaper.MIDIEditor_GetTake(midiEditor)

local nextNoteIdx = -1
local isFirstSelectedNote = true

while nextNoteIdx ~= -1 or isFirstSelectedNote do
    isFirstSelectedNote = false
    nextNoteIdx = reaper.MIDI_EnumSelNotes(take, nextNoteIdx)
    
    local retval, selected, muted, start, ends, channel, pitch, vel = reaper.MIDI_GetNote(take, nextNoteIdx)
    
    -- find next note number in array
    local customIdx = findNoteinCustomNames(pitch, customNoteOrder)
    if customIdx ~= -1 then
        -- set note pitch to next note
        -- Set MIDI note properties. Properties passed as NULL (or negative values) will not be set. Set noSort if setting multiple events, then call MIDI_Sort when done. Setting multiple note start positions at once is done more safely by deleting and re-inserting the notes.
        reaper.MIDI_SetNote(take, nextNoteIdx, true, muted, -1, -1, -1, customNoteOrder[customIdx - 1], -1, true)
    end
end