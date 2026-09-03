-- @description Track Compass - A fast and efficient way to navigate and focus in large projects.
-- @version 0.1.4
-- @author Luiza177
-- @about
--   # Track Compass
--   Inspired by LKC Tools Project Navigator, Track Compass allows you to focus on only the tracks you're working on without extra clutter.
--   With Focus View on, only selected tracks get shown. With it off, you get a representation of your tracks, use it to select and navigate around.
--   Regardless of what you do, Track Compass remembers the way you like your project set up.
--   On startup, it takes as snapshot of your project, this means:
--   - Archived or hidden tracks stay hidden
--   - MIDI only tracks (with hidden MCPs) only get their TCP recalled
--   - FX return tracks (hidden in the arrange view) only get their MCP recalled
--   If you add tracks later, press the * button (beside the ALL button), and a new snapshot is taken.
--   ## Other features:
--   - Ctrl/Cmd click for multi-select
--   - Alt/Opt click or turn on Solo mode for soloing
--   - Adapts to your theme
--   It's currently a work-in-progress, but the plan is to support a keyboard-centric (if desired), workflow, inspired by vim.
--   And, of course, add some bells and whistles.
--   ## (Current?) Limitations:
--   - No click-and-drag to select
--   - No toggling folder states
--   ## Roadmap:
--   - Option to not show hidden or MCP-only tracks in list
--   - Remember state when quit
--   - expand/collapse folders
--   - Save snapshot with project
--   - keyboard navigation
--   - allow drag-select
--   - represent solo state in list
--   - search + shortcuts
--   - represent track color in list
-- @changelog
--   - Defaults to showing TCP/MCP of newly created tracks, hide and recapture manually if different configuration
-- @provides
--   [main] .

if not reaper.ImGui_GetBuiltinPath then
	return reaper.MB("ReaImGui is not installed or too old.", "Track Compass -- ERROR", 0)
end

package.path = reaper.ImGui_GetBuiltinPath() .. "/?.lua;" .. package.path
local ImGui = require("imgui")("0.10")

local ctx = ImGui.CreateContext("Track Compass")
local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()

-- GLOBALS -----------------------------------------------------------------
local all_snapshot = {}
local pinned_tracks = {}
local focused_pinned_tracks = {}
local main_tracks = {}
local focused_main_tracks = {}
local last_alt_click = false
local last_main_click_ref = nil

----------------------------------------------------------------------------
-- CHECKBOX STUFF
local focus_view = true
local solo_selected = false
local keep_pinned = true

---------------------------------------------------------------------------
-- CONFIG VARS
ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverStationaryDelay, 0.7)

---------------------------------------------------------------------------
-- COLOR AND THEME METHODS
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
	-- local text_color = reaper.GetThemeColor("col_tcp_text", 0)
	local automation_recording = reaper.GetThemeColor("col_fadearm", 0)

	Theme_colors = {
		bg_color = ToImGuiColor(bg_color),
		bg2_color = ToImGuiColor(bg2_color),
		primary_color = ToImGuiColor(primary_color),
		secondary_color = ToImGuiColor(secondary_color),
		-- text_color = ToImGuiColor(text_color),
		automation_recording = ToImGuiColor(automation_recording),
	}
end
---------------------------------------------------------------------------
-- BUSINESS LOGIC AND HELPERS
local function UnsoloAll()
	reaper.Main_OnCommand(40340, 0) -- Track: Unsolo all tracks
end
local function SoloExclusive()
	UnsoloAll()
	reaper.Main_OnCommand(40728, 0) -- Track: Solo tracks
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
		else
			-- FIXME: show and add to all_snapshot? integer?
			reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
			reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
			all_snapshot[track] = { show_tcp = 1, show_mcp = 1 }
		end
	end
	reaper.TrackList_AdjustWindows(false) -- actually show changes
	focused_main_tracks = {}
	focused_pinned_tracks = {}
	UnsoloAll()
end

-- MAIN LIST
local function GetTrackName(track, i)
	local i = i or nil
	local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
	if name == "" then
		name = "Track " .. i + 1
	end
	return name
end

local function TrackPrefix(track)
	local indent_str = string.rep("    ", track.depth)
	local folder_str = ""
	if track.is_folder then
		folder_str = track.is_collapsed and "▸ " or "▾ "
	end
	return indent_str .. folder_str
end

local function GatherAllTrackInfo()
	local depth = 0
	pinned_tracks = {}
	main_tracks = {}

	for i = 0, reaper.CountTracks(0) - 1 do
		local track = reaper.GetTrack(0, i)
		local depth_change = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")

		local name = GetTrackName(track, i)
		local number = i + 1 --? or 0 based?
		local is_folder = depth_change == 1
		local color = reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR") -- OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
		local is_collapsed = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") == 2

		local track_info = {
			track_ref = track,
			name = name,
			number = number,
			depth = depth,
			is_folder = is_folder,
			is_collapsed = is_collapsed,
			color = color,
		}

		-- reaper.ShowConsoleMsg("\n" .. number .. " " .. name .. ":")
		-- reaper.ShowConsoleMsg("\n" .. "    depth:" .. depth)
		-- reaper.ShowConsoleMsg("\n" .. "    is_folder:" .. tostring(is_folder))
		-- reaper.ShowConsoleMsg("\n" .. "    is_collapsed:" .. tostring(is_collapsed))

		local is_pinned = reaper.GetMediaTrackInfo_Value(track, "B_TCPPIN") == 1
		if is_pinned then
			pinned_tracks[#pinned_tracks + 1] = track_info
		else
			main_tracks[#main_tracks + 1] = track_info
		end

		depth = depth + depth_change
	end
end

local function IsEntrySelected(track, focused_set)
	if focus_view then
		return focused_set[track.track_ref] == true
	else
		return reaper.IsTrackSelected(track.track_ref)
	end
end

local function FocusSelected(should_solo)
	for i = 0, reaper.CountTracks(0) - 1 do
		local track_ref = reaper.GetTrack(0, i)
		if focused_pinned_tracks[track_ref] == true or focused_main_tracks[track_ref] == true then
			local saved_track_state = all_snapshot[track_ref]
			if saved_track_state then
				reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINTCP", all_snapshot[track_ref].show_tcp)
				reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINMIXER", all_snapshot[track_ref].show_mcp)
			else
				reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINTCP", 1)
				reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINMIXER", 1)
				all_snapshot[track] = { show_tcp = 1, show_mcp = 1 } -- ? do we need this here or only in RestoreAllState?
			end
			if should_solo then
				reaper.SetMediaTrackInfo_Value(track_ref, "I_SOLO", 1)
			end
		else
			reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINTCP", 0)
			reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINMIXER", 0)
			if should_solo then
				reaper.SetMediaTrackInfo_Value(track_ref, "I_SOLO", 0)
			end
		end
	end
	reaper.TrackList_AdjustWindows(false) -- actually show changes
end

local function GetFolderChildren(track, set)
	local depth_to_select = track.depth + 1
	local current_depth = depth_to_select
	for i = track.number, reaper.CountTracks(0) - 1 do
		local other_track = reaper.GetTrack(0, i)
		local folder_depth_state = reaper.GetMediaTrackInfo_Value(other_track, "I_FOLDERDEPTH")

		set[other_track] = true

		current_depth = current_depth + folder_depth_state
		if current_depth < depth_to_select then
			return
		end
	end
end

local function AddPinnedTracks()
	for _, pinned_track in ipairs(pinned_tracks) do
		focused_pinned_tracks[pinned_track.track_ref] = true
	end
end

local function HandleClickTrack(track, is_pinned)
	local mods = ImGui.GetKeyMods(ctx)
	local ctrl_held = (mods & ImGui.Mod_Ctrl) ~= 0
	local shift_held = (mods & ImGui.Mod_Shift) ~= 0
	local alt_held = (mods & ImGui.Mod_Alt) ~= 0
	local should_solo = alt_held or solo_selected

	if not focus_view then
		if ctrl_held then -- multi-select
			if reaper.IsTrackSelected(track.track_ref) then
				reaper.SetTrackSelected(track.track_ref, false)
			else
				reaper.SetTrackSelected(track.track_ref, true)
			end
		else -- single select
			reaper.SetOnlyTrackSelected(track.track_ref)
		end
		if should_solo then
			SoloExclusive()
		end
		reaper.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view
		return
	end

	if last_alt_click and not alt_held then
		UnsoloAll()
	end

	-- SELECTION BEHAVIOR / what to select
	if is_pinned then -- if a PINNED track was clicked, always multi-select
		-- FIXME: when in ALL state, pinned tracks cannot be focused
		if focused_pinned_tracks[track.track_ref] then -- and is already selected then
			focused_pinned_tracks[track.track_ref] = nil -- unselect it
		else
			focused_pinned_tracks[track.track_ref] = true -- select it
			-- if track.is_folder then GetFolderChildren(track, focused_pinned_tracks) end -- and select children, if folder
		end
		-- if no pinned tracks remain focused, disable keep_pinned
		if next(focused_pinned_tracks) == nil then
			keep_pinned = false
		end
		-- keep_pinned = next(focused_pinned_tracks) ~= nil
	else -- clicked a MAIN track
		-- add pinned tracks if keep_pinned and no pinned tracks are focused
		--? move this to outside??
		if keep_pinned and next(focused_pinned_tracks) == nil then
			AddPinnedTracks()
		end
		if ctrl_held then -- multi-select
			if focused_main_tracks[track.track_ref] then -- already selected
				focused_main_tracks[track.track_ref] = nil -- unselect it
			else
				focused_main_tracks[track.track_ref] = true -- select it
				if track.is_folder then
					GetFolderChildren(track, focused_main_tracks)
				end -- and select children, if folder
			end
			last_main_click_ref = nil
		else -- single select
			if track.track_ref == last_main_click_ref then -- if single-select clicked the same track
				focused_main_tracks = {} -- or to restore ALL state later
				last_main_click_ref = nil
			else
				focused_main_tracks = { [track.track_ref] = true } -- single out clicked track
				if track.is_folder then
					GetFolderChildren(track, focused_main_tracks)
				end -- and select children, if folder
				last_main_click_ref = track.track_ref
			end
		end
	end

	-- WHAT TO DO ABOUT IT
	if next(focused_main_tracks) == nil then -- FIXME: and not keep_pinned??? (for pinned tracks not selectable)
		RestoreAllState()
	else
		FocusSelected(should_solo)
	end
	last_alt_click = alt_held
end

-- FIXME: EDGE CAGE when folder parent is pinned, but children are not (REAPER behavior)
local function RenderTrackList(set, focused_set, is_pinned)
	local skip_depth = nil
	for _, entry in ipairs(set) do
		if is_pinned or not skip_depth or entry.depth < skip_depth then
			local retval = ImGui.Selectable(
				ctx,
				entry.number .. " " .. TrackPrefix(entry) .. entry.name,
				IsEntrySelected(entry, focused_set)
			)
			if retval then
				HandleClickTrack(entry, is_pinned)
			end
			skip_depth = nil
			if entry.is_folder and entry.is_collapsed then
				skip_depth = entry.depth + 1
			end
		end
	end
end

--==============================================================
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
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 2)
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding, 1)
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize, 1)

		local mode_color = focus_view and Lighten(Theme_colors.primary_color, 0.1) or Theme_colors.primary_color

		ImGui.PushStyleColor(ctx, ImGui.Col_Border, SetAlpha(Lighten(Theme_colors.primary_color, 0.2), 0.2))
		ImGui.PushStyleColor(ctx, ImGui.Col_Border, SetAlpha(Darken(Theme_colors.bg2_color, 0.1), 0.1))
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
		ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFFFFFFFF)
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

		--------------------------- WINDOW SIZING
		local NUM_CHECKBOXES = 3
		local footer_height = ImGui.GetFrameHeightWithSpacing(ctx) * NUM_CHECKBOXES
		local list_height = -footer_height

		local available_width = ImGui.GetContentRegionAvail(ctx)
		local spacing_x = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)

		--------------------------- TOP BUTTONS
		ImGui.PushStyleVarX(ctx, ImGui.StyleVar_ItemSpacing, 2)
		local capture_button_width = 20

		-- ALL BUTTON
		if ImGui.Button(ctx, "ALL", available_width - capture_button_width - spacing_x, 0) then
			RestoreAllState()
		end
		ImGui.SetItemTooltip(
			ctx,
			"Show all desired tracks.\nThis keeps tracks that are shown in the TCP but not MCP (eg. MIDI only tracks) intact."
		)

		ImGui.SameLine(ctx)

		-- CAPTURE BUTTON
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

		----------------------------- LIST BOX
		ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, SetAlpha(Theme_colors.bg2_color, 1)) -- list box, checkbox bg
		-- -FLT_MIN = right align
		if ImGui.BeginListBox(ctx, "##tracks", -FLT_MIN, list_height) then
			GatherAllTrackInfo()
			RenderTrackList(pinned_tracks, focused_pinned_tracks, true)
			ImGui.Separator(ctx)
			RenderTrackList(main_tracks, focused_main_tracks, false)

			ImGui.EndListBox(ctx)
		end

		------------------------------ OPTIONS CHECKBOXES
		local focus_changed, focus_new = ImGui.Checkbox(ctx, "Focus view", focus_view)
		if focus_changed then
			focus_view = focus_new
			if not focus_view then
				RestoreAllState()
			end -- TODO: make it an option (restore ALL on going back to nav mode)
		end

		local solo_selected_change, solo_selected_new = ImGui.Checkbox(ctx, "Solo", solo_selected)
		if solo_selected_change then
			solo_selected = solo_selected_new
			if not solo_selected_new then
				UnsoloAll()
			end
		end

		local keep_pinned_change, keep_pinned_new = ImGui.Checkbox(ctx, "Keep pinned tracks", keep_pinned)
		if keep_pinned_change then
			keep_pinned = keep_pinned_new
			if
				focus_view
				and keep_pinned
				and next(focused_main_tracks) ~= nil
				and next(focused_pinned_tracks) == nil
			then
				AddPinnedTracks()
				FocusSelected(solo_selected)
			elseif focus_view and not keep_pinned and next(focused_pinned_tracks) ~= nil then
				focused_pinned_tracks = {}
				FocusSelected(solo_selected)
			end
		end
		ImGui.SetItemTooltip(ctx, "Keep pinned tracks while focusing")

		ImGui.PopStyleVar(ctx, 1) -- frame border
		---------------------

		ImGui.PopStyleVar(ctx, 3)
		ImGui.PopStyleColor(ctx, 21)
		ImGui.End(ctx)
	end

	if open then
		reaper.defer(loop)
	end
end

CaptureAllState() -- TODO: on project change?
CaptureCurrentTheme() -- TODO: on theme change

reaper.defer(loop)
