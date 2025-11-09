-- @description Transpose notes down to next visible note in Custom Note Order mode
-- @author Luiza177
-- @version 1.3
-- @provides
--   [nomain] .
--   [main] luiza177_Transpose down to previous note in custom view.lua
--   [main] luiza177_Transpose up to next note in custom view.lua
-- @about Transpose MIDI notes up or down to next visible note in Custom Note Order view (or just transpose notes by a semitone)
-- @changelog
--   Optimizations. 

-- FUNCTIONS ----------------------------------------------------------------
local function findNoteinCustomNames(num, customNoteNames)
    for i = 1, #customNoteNames do
        if (customNoteNames[i] == num) then
            return i
        end
    end
    return -1
end

local function getCustomNoteOrder(track)
    local retval, trackStateChunk = reaper.GetTrackStateChunk(track, "", false)
    local customNoteOrder = {}

    if (not retval) then
        reaper.ShowConsoleMsg("Could not get Track state chunk")
        return customNoteOrder
    end
    
    for notes in trackStateChunk:gmatch('CUSTOM_NOTE_ORDER(.-)\n') do
        -- reaper.ShowConsoleMsg("'"..notes.."'" .. "\n")
        for num in notes:gmatch("%S+") do
            customNoteOrder[#customNoteOrder+1] = tonumber(num) --? needs to be +1 ??
        end
    end
    return customNoteOrder
end

local function doNativeTranspose(midiEditor, upOrDown)
    if upOrDown == -1 then
        reaper.MIDIEditor_OnCommand(midiEditor, 40178) -- Edit: Move notes down one semitone
    else 
        reaper.MIDIEditor_OnCommand(midiEditor, 40177) -- Edit: Move notes up one semitone
    end
end

----------------------------------------------------------------------------
function TransposeCustom(upOrDown) -- 1 or -1
    local midiEditor = reaper.MIDIEditor_GetActive()
    
    local isCustomNoteView = reaper.GetToggleCommandStateEx(32060, 40143) -- MIDI Editor, View: Show custom note row view
    
    -- if not custom note view then just normal transpose
    if (isCustomNoteView ~= 1) then
        -- reaper.ShowConsoleMsg("Normal\n")
        doNativeTranspose(midiEditor, upOrDown)
        return
    end

    -- reaper.ShowConsoleMsg("Drum Transpose\n")
    local take = reaper.MIDIEditor_GetTake(midiEditor)
    local item = reaper.GetMediaItemTake_Item(take)
    local track = reaper.GetMediaItem_Track(item)
    local customNoteOrder = getCustomNoteOrder(track)
    if #customNoteOrder == 0 then
        -- reaper.ShowConsoleMsg("No custom note order\n")
        doNativeTranspose(midiEditor, upOrDown)
        return
    end
    
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
            reaper.MIDI_SetNote(take, nextNoteIdx, true, muted, -1, -1, -1, customNoteOrder[customIdx + upOrDown], -1, true)
        end
    end
    -- workaround for note preview
    -- NOTE: ALL options for previewing notes (except for "Preview all selected notes that overlap with the edited note (when preview is enabled)", which is irrelevant) must be enabled
    reaper.PreventUIRefresh(1)
    reaper.MIDIEditor_OnCommand(midiEditor, 40464) --Edit: Note velocity -01
    reaper.MIDIEditor_OnCommand(midiEditor, 40462) --Edit: Note velocity +01
    reaper.PreventUIRefresh(-1)
end
