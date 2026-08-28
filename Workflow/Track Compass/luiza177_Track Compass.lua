if not reaper.ImGui_GetBuiltinPath then
	return reaper.MB("ReaImGui is not installed or too old.", "Track Compass", 0)
end

package.path = reaper.ImGui_GetBuiltinPath() .. "/?.lua;" .. package.path
local ImGui = require("imgui")("0.10")

local ctx = ImGui.CreateContext("Track Compass")
local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()

-- GENERAL
-- TODO: tooltip delay longer and stationary
-- clean up colors
-- refactor
-- optimize

-- FUNCTIONALITY
-- TODO: option to leave PINNED tracks alone
-- TODO: option to hide tracks with hidden TCP
-- TODO: remember state when quit
-- later
-- TODO: Auto monitoring of new tracks

-- WORKFLOW
-- TODO: ignore non-shortcut key commands
-- TODO: allow drag select
-- TODO: allow toggling folder state -- needs changing from Listbox to (selectable) Tree
-- TODO: keyboard workflow
-- -- arrow or vim navigation
-- -- shortcuts to focus main reaper window and ImGui window / back and forth
-- later
-- TODO: search + shortcuts
-- ? scroll to content?
-- TODO: represent solo state in list
-- ? display track number?

-- STYLE
-- TODO: call attention to solo mode
-- later
-- TODO: represent pinned track
-- TODO: track color in selectable
-- TODO: ensure readable text

-- GLOBALS -----------------------------------------------------------------
local all_snapshot = {}
local clicked_tracks = {}
local last_alt_click = false

----------------------------------------------------------------------------
-- CHECKBOX STUFF
local focus_view = true
local solo_selected = false

---------------------------------------------------------------------------
local function SetAlpha(color, alpha)
	-- alpha: 0.0 (fully transparent) to 1.0 (fully opaque)
	local alpha_byte = math.floor(alpha * 255 + 0.5)
	return (color & 0xFFFFFF00) | alpha_byte
end

local function Darken(color, amount)
	-- amount: 0.0 (no change) to 1.0 (fully black). Preserves existing alpha.
	local r = (color >> 24) & 0xFF
	local g = (color >> 16) & 0xFF
	local b = (color >> 8) & 0xFF
	local a = color & 0xFF

	r = math.floor(r * (1 - amount))
	g = math.floor(g * (1 - amount))
	b = math.floor(b * (1 - amount))

	return (r << 24) | (g << 16) | (b << 8) | a
end

local function Lighten(color, amount)
	-- amount: 0.0 (no change) to 1.0 (fully white). Preserves existing alpha.
	local r = (color >> 24) & 0xFF
	local g = (color >> 16) & 0xFF
	local b = (color >> 8) & 0xFF
	local a = color & 0xFF

	r = math.floor(r + (255 - r) * amount)
	g = math.floor(g + (255 - g) * amount)
	b = math.floor(b + (255 - b) * amount)

	return (r << 24) | (g << 16) | (b << 8) | a
end

-- local function GetReadableTextColor(bg_color, light_color, dark_color)
--     -- bg_color: 0xRRGGBBAA background color to check against
--     -- light_color/dark_color: optional overrides (default white/black), same 0xRRGGBBAA format
--     light_color = light_color or 0xFFFFFFFF
--     dark_color = dark_color or 0x000000FF

--     local r = (bg_color >> 24) & 0xFF
--     local g = (bg_color >> 16) & 0xFF
--     local b = (bg_color >> 8) & 0xFF

--     -- perceived brightness (weighted for human eye sensitivity: green reads brightest, blue darkest)
--     local brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255

--     if brightness > 0.5 then
--         return dark_color -- light background -> dark text
--     else
--         return light_color -- dark background -> light text
--     end
-- end

local function ToImGuiColor(color)
	local converted = ImGui.ColorConvertNative(color)
	return (converted << 8 | 0xFF)
end

local function CaptureCurrentTheme()
	Theme_colors = {}
	local bg_color = reaper.GetThemeColor("col_main_bg2", 0) -- or col_main_bg, col_main_bg2, windowtab_bg
	local bg2_color = reaper.GetThemeColor("col_tracklistbg", 0) -- or genlist_bg, col_tracklistbg
	local primary_color = reaper.GetThemeColor("genlist_selbg", 0) -- or col_toolbar_text_on, genlist_selbg, col_cursor
	local secondary_color = reaper.GetThemeColor("playcursor_color", 0)
	local text_color = reaper.GetThemeColor("col_tcp_text", 0)
	local automation_recording = reaper.GetThemeColor("col_fadearm", 0)

	Theme_colors = {
		bg_color = ToImGuiColor(bg_color),
		bg2_color = ToImGuiColor(bg2_color),
		primary_color = ToImGuiColor(primary_color),
		secondary_color = ToImGuiColor(secondary_color),
		text_color = ToImGuiColor(text_color),
		automation_recording = ToImGuiColor(automation_recording),
	}
end

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
	ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, 2)
	ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 8, 8)

	ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, Theme_colors.bg_color)
	ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg, Theme_colors.bg_color)
	ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive, Theme_colors.bg2_color)
	ImGui.PushStyleColor(ctx, ImGui.Col_Tab, SetAlpha(Theme_colors.bg2_color, 0.45))
	ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered, SetAlpha(Lighten(Theme_colors.bg2_color, 0.15), 0.8))
	ImGui.PushStyleColor(ctx, ImGui.Col_TabSelected, Theme_colors.bg2_color)
	ImGui.PushStyleColor(ctx, ImGui.Col_TabSelectedOverline, Theme_colors.primary_color)
	ImGui.PushStyleColor(ctx, ImGui.Col_TabDimmed, SetAlpha(Darken(Theme_colors.bg2_color, 0.2), 0.98))
	ImGui.PushStyleColor(ctx, ImGui.Col_TabDimmedSelected, SetAlpha(Theme_colors.bg2_color, 0.3))
	ImGui.PushStyleColor(ctx, ImGui.Col_TabDimmedSelectedOverline, SetAlpha(Theme_colors.primary_color, 0))
	ImGui.PushStyleColor(ctx, ImGui.Col_DockingPreview, SetAlpha(Theme_colors.primary_color, 0.7))
	ImGui.PushStyleColor(ctx, ImGui.Col_DockingEmptyBg, Theme_colors.bg2_color)

	local window_flags = ImGui.WindowFlags_NoCollapse
	local visible, open = ImGui.Begin(ctx, "Track Compass", true, window_flags)

	ImGui.PopStyleVar(ctx, 2)
	ImGui.PopStyleColor(ctx, 12)

	if visible then
		-- STYLE
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 2)
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding, 1)
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize, 1)
		-- local font = ImGui.CreateFont('font name', 14) --* get from theme
		-- ImGui.Attach(ctx, font)
		-- ImGui.PushFont(ctx, font)
		-- ImGui.PopFont(ctx)

		local mode_color = focus_view and Lighten(Theme_colors.primary_color, 0.1) or Theme_colors.primary_color

		ImGui.PushStyleColor(ctx, ImGui.Col_Button, SetAlpha(Darken(mode_color, 0.2), 0.6))
		ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, Darken(mode_color, 0.1))
		ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, SetAlpha(Darken(mode_color, 0.1), 0.67))
		ImGui.PushStyleColor(ctx, ImGui.Col_Header, SetAlpha(mode_color, 0.25)) -- list item
		ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, SetAlpha(mode_color, 0.45))
		ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered, SetAlpha(mode_color, 0.35))
		ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, SetAlpha(Theme_colors.bg2_color, 0.4)) -- list box, checkbox bg
		ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, SetAlpha(Theme_colors.bg2_color, 0.4))
		ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, SetAlpha(Theme_colors.bg2_color, 0.6))
		ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark, mode_color)
		ImGui.PushStyleColor(ctx, ImGui.Col_Text, Theme_colors.text_color)
		ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGrip, SetAlpha(Theme_colors.primary_color, 0.2))
		ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripActive, SetAlpha(Theme_colors.primary_color, 0.67))
		ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripHovered, SetAlpha(Theme_colors.primary_color, 0.95))
		ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarBg, SetAlpha(Darken(Theme_colors.bg2_color, 0.15), 0.5))
		ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarGrab, SetAlpha(Theme_colors.primary_color, 1))
		ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarGrabActive, SetAlpha(Theme_colors.primary_color, 1))
		ImGui.PushStyleColor(
			ctx,
			ImGui.Col_ScrollbarGrabHovered,
			SetAlpha(Lighten(Theme_colors.primary_color, 0.15), 1)
		)
		local track_count = reaper.CountTracks(0)

		-- WINDOW SIZING
		local NUM_CHECKBOXES = 2
		local footer_height = ImGui.GetFrameHeightWithSpacing(ctx) * NUM_CHECKBOXES
		local list_height = -footer_height

		ImGui.PushStyleVarX(ctx, ImGui.StyleVar_ItemSpacing, 2)
		-- ALL button + capture button. ALL should take up most of the space. both take up full width
		local available_width = ImGui.GetContentRegionAvail(ctx)

		local spacing_x = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)

		local capture_button_width = 20
		if ImGui.Button(ctx, "ALL", available_width - capture_button_width - spacing_x, 0) then
			RestoreAllState()
		end
		ImGui.SetItemTooltip(
			ctx,
			"Show all desired tracks.\nThis keeps tracks that are shown in the TCP but not MCP (eg. MIDI only tracks) intact."
		)

		ImGui.SameLine(ctx)

		ImGui.PushStyleColor(ctx, ImGui.Col_Button, SetAlpha(Theme_colors.automation_recording, 0.5))
		ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, Theme_colors.automation_recording)
		ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, SetAlpha(Theme_colors.automation_recording, 0.67))

		if ImGui.Button(ctx, "*", capture_button_width, 0) then
			CaptureAllState()
		end
		ImGui.SetItemTooltip(
			ctx,
			"Capture default project state showing all desired tracks.\nIf you have tracks that are shown in the TCP but not MCP (eg. MIDI only tracks), this will keep that intact."
		)

		ImGui.PopStyleColor(ctx, 3)
		ImGui.PopStyleVar(ctx, 1)

		ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, SetAlpha(Theme_colors.bg2_color, 1)) -- list box, checkbox bg
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
					local indent_str = string.rep("    ", depth)

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

					-- ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign, 0.04, 0.5)
					-------------- ON-CLICK ACTION --------------
					if ImGui.Selectable(ctx, " " .. indent_str .. prefix .. name .. "##" .. i, is_selected) then
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
					-- ImGui.PopStyleVar(ctx, 1) -- selectable text align
					---------------------------------------------

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
		ImGui.PopStyleVar(ctx, 1) -- frame border
		---------------------

		ImGui.PopStyleVar(ctx, 3)
		ImGui.PopStyleColor(ctx, 19)
		ImGui.End(ctx)
	end

	if open then
		reaper.defer(loop)
	end
end

CaptureAllState()
CaptureCurrentTheme()
-- reaper.ShowConsoleMsg("\nWindow DPI scale: " .. ImGui.GetWindowDpiScale(ctx))
reaper.defer(loop)
