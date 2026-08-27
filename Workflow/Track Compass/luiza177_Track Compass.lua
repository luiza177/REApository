if not reaper.ImGui_GetBuiltinPath then
	return reaper.MB("ReaImGui is not installed or too old.", "Track Compass", 0)
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
-- TODO: remember state when quit

-- UI
-- TODO: allow drag select
-- TODO: allow toggling folder state
-- TODO: keyboard workflow
-- -- arrow or vim navigation
-- -- shortcuts to focus main reaper window and ImGui window / back and forth
-- TODO: search + shortcuts

-- GLOBALS -----------------------------------------------------------------
local all_snapshot = {}
local clicked_tracks = {}
local last_alt_click = false

----------------------------------------------------------------------------
-- CHECKBOX STUFF
local focus_view = true
local solo_selected = false

---------------------------------------------------------------------------
local function UnsoloAll()
	reaper.Main_OnCommand(40340, 0)
end -- Track: Unsolo all tracks
local function SoloExclusive()
	UnsoloAll()
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
	UnsoloAll()
end

local function GetAllTracksToFocus()
	local all_focused_tracks = {}
	local depth = 0
	local show_all_depth = nil

	-- reaper.ShowConsoleMsg("\nSTART\n")

	for i = 0, reaper.CountTracks(0) - 1 do
		local track = reaper.GetTrack(0, i)
		-- reaper.ShowConsoleMsg("\n" .. i .. " " .. GetTrackName(track))
		local folder_state = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
		-- reaper.ShowConsoleMsg("\n current depth: " .. depth )
		-- reaper.ShowConsoleMsg("\n folder_state: " .. folder_state )
		-- reaper.ShowConsoleMsg("\n show_all_depth: " .. tostring(show_all_depth))

		if show_all_depth ~= nil and depth >= show_all_depth then
			-- reaper.ShowConsoleMsg("\n   adding track and continuing")
			all_focused_tracks[track] = true
			goto continue
		elseif show_all_depth ~= nil and depth < show_all_depth then
			-- reaper.ShowConsoleMsg("\n   depth fell below show all, resetting to nil")
			show_all_depth = nil
		end

		if clicked_tracks[track] == true then
			all_focused_tracks[track] = true
			-- reaper.ShowConsoleMsg("\n   add track")
			if folder_state == 1 then
				show_all_depth = depth + folder_state
				-- reaper.ShowConsoleMsg(" and setting show_all_depth to " .. show_all_depth)
			end
		end

		::continue::

		depth = depth + folder_state
	end

	return all_focused_tracks
end

local function FocusSelected(should_solo)
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
			if should_solo then
				reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 1)
			end
		else
			reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
			reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
			if should_solo then
				reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 0)
			end
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
						is_selected = clicked_tracks[track] == true
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
						local mods = ImGui.GetKeyMods(ctx)

						local ctrl_held = (mods & ImGui.Mod_Ctrl) ~= 0
						-- local shift_held = (mods & ImGui.Mod_Shift) ~= 0
						local alt_held = (mods & ImGui.Mod_Alt) ~= 0
						local should_solo = alt_held or solo_selected

						if focus_view then
							local unselect = false
							if last_alt_click and not alt_held then
								UnsoloAll()
							end
							if not ctrl_held then
								if clicked_tracks[track] then
									unselect = true
								end
								clicked_tracks = {}
							end
							reaper.SetOnlyTrackSelected(track)

							if clicked_tracks[track] == true or unselect then
								clicked_tracks[track] = nil
							else
								clicked_tracks[track] = true
							end

							if next(clicked_tracks) == nil then
								RestoreAllState()
							else
								FocusSelected(should_solo)
							end
							last_alt_click = alt_held
						else
							if ctrl_held then
								if reaper.IsTrackSelected(track) then
									reaper.SetTrackSelected(track, false)
								else
									reaper.SetTrackSelected(track, true)
								end
							else
								reaper.SetOnlyTrackSelected(track)
							end
							if should_solo then
								SoloExclusive()
							end
						end
						reaper.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view
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

		local solo_selected_change, solo_selected_new = ImGui.Checkbox(ctx, "Solo", solo_selected)
		if solo_selected_change then
			solo_selected = solo_selected_new
			if not solo_selected_new then
				UnsoloAll()
			end
		end
		---------------------

		ImGui.End(ctx)
	end

	if open then
		reaper.defer(loop)
	end
end

reaper.defer(loop)
