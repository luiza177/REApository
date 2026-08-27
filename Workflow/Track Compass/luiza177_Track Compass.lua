if not reaper.ImGui_GetBuiltinPath then
	return reaper.MB("ReaImGui is not installed or too old.", "My script", 0)
end

package.path = reaper.ImGui_GetBuiltinPath() .. "/?.lua;" .. package.path
local ImGui = require("imgui")("0.10")

local ctx = ImGui.CreateContext("Track Compass")
local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()

-- UI
-- TODO: resize from edges
-- TODO: tooltip delay longer and stationary
-- TODO: dock
-- TODO: different color selection highlight for nav and focus mode

-- FUNCTIONALITY
-- ? TODO: don't touch MCP-only tracks? (AKA sends)
-- TODO: ACCOUNT FOR TRACKS THAT GET CREATED LATER for ALL state
-- TODO: preference for unsoloing when ALL is restored
-- TODO: remember state when quit

-- UI
-- TODO: allow multi-select in focus mode
-- TODO: allow multi-select in nav mode
-- TODO: allow drag select
-- TODO: allow toggling folder state
-- TODO: keyboard workflow
-- -- arrow or vim navigation
-- -- shortcuts to focus main reaper window and ImGui window / back and forth
-- TODO: search + shortcuts

-- GLOBALS -----------------------------------------------------------------
local all_snapshot = {}
-- local focused_track = nil
local focused_tracks = {}

----------------------------------------------------------------------------
-- CHECKBOX STUFF
local focus_view = true
local solo_selected = false

---------------------------------------------------------------------------
local function SoloExclusive()
	reaper.Main_OnCommand(40340, 0) -- Track: Unsolo all tracks
	reaper.Main_OnCommand(40728, 0) -- Track: Solo tracks
end

local function GetTrackName(track)
	local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
	if name == "" then
		local track_num = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
		name = "Track " .. tostring(math.floor(track_num))
	end
	return name
end

local function CaptureAllState()
	for i = 0, reaper.CountTracks(0) - 1 do
		local track = reaper.GetTrack(0, i)
		local show_tcp = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP")
		local show_mcp = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINMIXER")
		-- reaper.ShowConsoleMsg("\ntrack: " .. GetTrackName(track) .. "\n")
		-- reaper.ShowConsoleMsg("   TCP: " .. show_tcp .. "\n")
		-- reaper.ShowConsoleMsg("   MCP: " .. show_mcp .. "\n")
		all_snapshot[track] = { show_tcp = show_tcp, show_mcp = show_mcp }
	end
end

local function RestoreAllState()
	for i = 0, reaper.CountTracks(0) - 1 do
		local track = reaper.GetTrack(0, i)
		local saved_track_state = all_snapshot[track]
		if saved_track_state then
			reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", all_snapshot[track].show_tcp)
			reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", all_snapshot[track].show_mcp)
		end
	end
	reaper.TrackList_AdjustWindows(false) -- actually show changes
	-- focused_track = nil
	focused_tracks = {}
	-- reaper.ShowConsoleMsg("\nrestored all state")
end

-- local function FocusSelected(target)
--     reaper.SetOnlyTrackSelected(target)

--     local is_folder_parent = reaper.GetMediaTrackInfo_Value(target, 'I_FOLDERDEPTH') == 1
--     if is_folder_parent then
--         local select_children_cmd = reaper.NamedCommandLookup("_SWS_SELCHILDREN2") -- SWS: Select children of selected folder track(s)
--         reaper.Main_OnCommand(select_children_cmd, 0)
--         reaper.TrackList_AdjustWindows(false)

--     end

--     for i = 0, reaper.CountSelectedTracks(0) - 1 do
--         local track = reaper.GetSelectedTrack(0, i)
--         local saved_track_state = all_snapshot[track]
--         if saved_track_state then
--             reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", all_snapshot[track].show_tcp)
--             reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", all_snapshot[track].show_mcp)
--         else
--             reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
--             reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
--         end
--     end

--     -- --! going to be a problem for multi select?
--     local invert_selection_cmd = reaper.NamedCommandLookup("_SWS_TOGTRACKSEL") -- SWS: Toggle (invert) track selection
--     reaper.Main_OnCommand(invert_selection_cmd, 0)
--     reaper.Main_OnCommand(41593, 0) -- Track: Hide tracks in TCP and mixer
--     -- TODO: account for MCP-only tracks/sends

--     reaper.SetOnlyTrackSelected(target)
-- end

local function GetAllTracksToFocus()
	local all_focused_tracks = {}
	local depth = 0
	local active_depth = nil

	for i = 0, reaper.CountTracks(0) - 1 do
		local track = reaper.GetTrack(0, i)
		local folder_depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")

		if active_depth ~= nil and depth <= active_depth then
			active_depth = nil
		end

		if focused_tracks[track] == true then
			all_focused_tracks[track] = true
			if folder_depth == 1 then
				active_depth = depth
			end
		elseif active_depth ~= nil then
			all_focused_tracks[track] = true
		end

		depth = depth + folder_depth
		if depth < 0 then
			depth = 0
		end
	end

	return all_focused_tracks
end

local function FocusSelected()
	local focused_tracks_and_children = GetAllTracksToFocus()
	for i = 0, reaper.CountTracks(0) - 1 do
		local track = reaper.GetTrack(0, i)
		if focused_tracks_and_children[track] == true then
			local saved_track_state = all_snapshot[track]
			if saved_track_state then
				reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", all_snapshot[track].show_tcp)
				reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", all_snapshot[track].show_mcp)
			else
				reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
				reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
			end
		else
			reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
			reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
		end
	end
	reaper.TrackList_AdjustWindows(false) -- actually show changes
end

---------------------------------------------------------------------------
local function loop()
	local window_flags = ImGui.WindowFlags_NoCollapse
	local visible, open = ImGui.Begin(ctx, "Track Compass", true, window_flags)
	if visible then
		local track_count = reaper.CountTracks(0)

		-- WINDOW SIZING
		local NUM_CHECKBOXES = 2
		local footer_height = ImGui.GetFrameHeightWithSpacing(ctx) * NUM_CHECKBOXES
		local list_height = -footer_height

		-- ALL button + capture button. ALL should take up most of the space. both take up full width
		local available_width = ImGui.GetContentRegionAvail(ctx)
		local spacing_x = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
		local capture_button_width = 30
		if ImGui.Button(ctx, "ALL", available_width - capture_button_width - spacing_x, 0) then
			RestoreAllState()
		end
		ImGui.SetItemTooltip(
			ctx,
			"Show all desired tracks.\nThis keeps tracks that are shown in the TCP but not MCP (eg. MIDI only tracks) intact."
		)

		ImGui.SameLine(ctx)

		if ImGui.Button(ctx, "*", capture_button_width, 0) then
			CaptureAllState()
		end
		ImGui.SetItemTooltip(
			ctx,
			"Capture default project state showing all desired tracks.\nIf you have tracks that are shown in the TCP but not MCP (eg. MIDI only tracks), this will keep that intact."
		)

		-- -FLT_MIN = right align
		if ImGui.BeginListBox(ctx, "##tracks", -FLT_MIN, list_height) then
			local depth = 0
			local skip_below_depth = nil -- if set, hide tracks deeper than this

			for i = 0, track_count - 1 do
				local track = reaper.GetTrack(0, i)
				local folder_depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")

				if skip_below_depth ~= nil and depth <= skip_below_depth then
					skip_below_depth = nil
				end

				if skip_below_depth == nil then
					-- render track normally
					local name = GetTrackName(track)
					local indent_px = depth * ImGui.StyleVar_IndentSpacing
					if indent_px > 0 then
						ImGui.Indent(ctx, indent_px)
					end

					local is_folder_parent = (folder_depth == 1)
					local folder_compact = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")
					local is_collapsed = is_folder_parent and folder_compact == 2

					local prefix = ""
					if is_folder_parent then
						prefix = is_collapsed and "▸ " or "▾ "
					end

					local is_selected
					if focus_view then
						-- is_selected = (track == focused_track)
						is_selected = focused_tracks[track] == true
					else
						is_selected = reaper.IsTrackSelected(track)
					end

					-- ? only bother showing TCP tracks? MCP-only tracks are probably sends, so don't touch them?
					-------------- ON-CLICK ACTION --------------
					if
						ImGui.Selectable(
							ctx,
							prefix .. name .. "##" .. i,
							is_selected,
							ImGui.SelectableFlags_SpanAllColumns
						)
					then
						if focus_view then
							if focused_tracks[track] == true then
								focused_tracks[track] = nil
							else
								focused_tracks[track] = true
							end

							if next(focused_tracks) == nil then
								RestoreAllState()
							else
								FocusSelected()
							end
						else
							reaper.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view
						end
						if solo_selected then
							SoloExclusive()
						end
					end
					---------------------------------------------

					if indent_px > 0 then
						ImGui.Unindent(ctx, indent_px)
					end

					-- start skipping children if this folder is collapsed
					if is_collapsed then
						skip_below_depth = depth
					end
				end

				-- update depth for the NEXT track based on this track's folder change
				depth = depth + folder_depth
				if depth < 0 then
					depth = 0
				end
			end

			ImGui.EndListBox(ctx)
		end

		------------------ OPTIONS
		local focus_changed, focus_new = ImGui.Checkbox(ctx, "Focus view", focus_view)
		if focus_changed then
			focus_view = focus_new
		end

		-- TODO: implement
		local solo_selected_change, solo_selected_new = ImGui.Checkbox(ctx, "Solo", solo_selected)
		if solo_selected_change then
			solo_selected = solo_selected_new
		end
		---------------------

		ImGui.End(ctx)
	end

	if open then
		reaper.defer(loop)
	end
end

reaper.defer(loop)
