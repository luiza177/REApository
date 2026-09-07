-- @description Track Compass - A fast and efficient way to navigate and focus in large projects.
-- @version 0.3.0
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
--   - expand/collapse folders
--   - keyboard navigation
--   - allow drag-select
--   - search + shortcuts
--   - represent track color in list
-- @changelog
--   - Reworked 'Keep pinned tracks' into 'Show pinned tracks': it now acts more of a show/hide toggle, while still only showing the ones you actually want
--   - Added button to adapt to theme colors
--   - hard-coded red color for solo indicator and capture button
--   - Removed modal at project load without any saved data: a new project will be assumed to show everything, until ALL state is captured.
--   - When project has no saved ALL state data, capture button will be red, otherwise grey
-- @provides
--   [main] .

if not reaper.ImGui_GetBuiltinPath then
	return reaper.MB("ReaImGui is not installed or too old.", "Track Compass -- ERROR", 0)
end

package.path = reaper.ImGui_GetBuiltinPath() .. "/?.lua;" .. package.path
local ImGui = require("imgui")("0.10")

local ctx = ImGui.CreateContext("Track Compass")
local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()
local ext_name = "luiza177.TrackCompass"

-- GLOBALS -----------------------------------------------------------------
local all_snapshot = {}
local pinned_tracks = {}
local focused_pinned_tracks = {}
local main_tracks = {}
local focused_main_tracks = {}
local last_alt_click = false
local last_main_click_ref = nil
local last_known_project = reaper.EnumProjects(-1)
local pending_loaded_entries = nil
local no_saved_data = false

----------------------------------------------------------------------------
-- CHECKBOX STUFF
local focus_view = true
local solo_selected = false
local show_pinned = true
local show_mcp_only_tracks = true
local show_hidden_tracks = false
local only_folder_parents = false

---------------------------------------------------------------------------
-- CONFIG VARS
ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverStationaryDelay, 0.7)

---------------------------------------------------------------------------
-- GENERAL HELPERS
local function SaveBoolState(key, value)
	reaper.SetExtState(ext_name, key, value and "1" or "0", true)
end

local function LoadBoolState(key, default)
	local value = reaper.GetExtState(ext_name, key)
	if value == "" then
		return default
	end
	return value == "1"
end

local function GetTrackName(track, i)
	local i = i or nil
	local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
	if name == "" then
		name = "Track " .. i + 1
	end
	return name
end

local function GatherAllTrackInfo()
	local depth = 0
	pinned_tracks = {}
	main_tracks = {}

	for i = 0, reaper.CountTracks(0) - 1 do
		local track_ref = reaper.GetTrack(0, i)
		local depth_change = reaper.GetMediaTrackInfo_Value(track_ref, "I_FOLDERDEPTH")

		local name = GetTrackName(track_ref, i)
		local _, guid = reaper.GetSetMediaTrackInfo_String(track_ref, "GUID", "", false)
		local number = i + 1
		local is_folder = depth_change == 1
		local color = reaper.GetMediaTrackInfo_Value(track_ref, "I_CUSTOMCOLOR") -- OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
		local is_collapsed = reaper.GetMediaTrackInfo_Value(track_ref, "I_FOLDERCOMPACT") == 2
		local show_tcp = reaper.GetMediaTrackInfo_Value(track_ref, "B_SHOWINTCP")
		local show_mcp = reaper.GetMediaTrackInfo_Value(track_ref, "B_SHOWINMIXER")

		local track_info = {
			track_ref = track_ref,
			guid = guid,
			name = name,
			number = number,
			depth = depth,
			is_folder = is_folder,
			is_collapsed = is_collapsed,
			color = color,
			show_tcp = show_tcp,
			show_mcp = show_mcp,
		}

		local is_pinned = reaper.GetMediaTrackInfo_Value(track_ref, "B_TCPPIN") == 1
		if is_pinned then
			pinned_tracks[#pinned_tracks + 1] = track_info
		else
			main_tracks[#main_tracks + 1] = track_info
		end

		depth = depth + depth_change
	end
end

local function ReadProjStoredState(track)
	local retval, value = reaper.GetProjExtState(0, ext_name, track.guid)
	if retval == 1 then
		local show_tcp_str, show_mcp_str = value:match("([^;]+);([^;]+)")
		-- reaper.ShowConsoleMsg("\nreading value for " .. track.name .. ", GUID: " .. track.guid .. ", show TCP: " .. show_tcp_str .. ", show MCP: " .. show_mcp_str)
		all_snapshot[track.track_ref] = {
			show_tcp = tonumber(show_tcp_str),
			show_mcp = tonumber(show_mcp_str),
			guid = track.guid,
		}
		-- else
		-- reaper.ShowConsoleMsg("\nNo value for " .. track.name .. ", GUID: " .. track.guid .. " was found!")
		--? add to all_snap here??
	end
	return retval
end

local function NoFocusedPinnedTracks()
	return next(focused_pinned_tracks) == nil
end

local function NoFocusedMainTracks()
	return next(focused_main_tracks) == nil
end

local function IsInAllState()
	return NoFocusedPinnedTracks() and NoFocusedMainTracks()
end

local function IsVisible(track)
	local tcp = reaper.GetMediaTrackInfo_Value(track.track_ref, "B_SHOWINTCP")
	local mcp = reaper.GetMediaTrackInfo_Value(track.track_ref, "B_SHOWINMIXER")
	return tcp == 1 or mcp == 1
end

local function IsTCPOnly(track_ref)
	if not all_snapshot[track_ref] then
		return false
	end
	return all_snapshot[track_ref].show_mcp == 0 and all_snapshot[track_ref].show_tcp == 1
end

local function IsMCPOnly(track_ref)
	if not all_snapshot[track_ref] then
		return false
	end
	return all_snapshot[track_ref].show_mcp == 1 and all_snapshot[track_ref].show_tcp == 0
end

local function IsArchived(track_ref)
	if not all_snapshot[track_ref] then
		return false
	end
	return all_snapshot[track_ref].show_mcp == 0 and all_snapshot[track_ref].show_tcp == 0
end

local function SetTCPOnly(track_ref)
	all_snapshot[track_ref].show_tcp = 1
	all_snapshot[track_ref].show_mcp = 0
end

local function SetMCPOnly(track_ref)
	all_snapshot[track_ref].show_tcp = 0
	all_snapshot[track_ref].show_mcp = 1
end

local function SetArchived(track_ref)
	all_snapshot[track_ref].show_tcp = 0
	all_snapshot[track_ref].show_mcp = 0
end

local function SetNormal(track_ref)
	all_snapshot[track_ref].show_tcp = 1
	all_snapshot[track_ref].show_mcp = 1
end

local function CountKeys(t)
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end
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
	-- local text_color = reaper.GetThemeColor("col_tcp_text", 0) -- TODO: find better text color
	-- local automation_recording = reaper.GetThemeColor("col_fadearm", 0)
	local red = 0xFD4F4FFF -- TODO: find a way to derive red from theme

	Theme_colors = {
		bg_color = ToImGuiColor(bg_color),
		bg2_color = ToImGuiColor(bg2_color),
		primary_color = ToImGuiColor(primary_color),
		secondary_color = ToImGuiColor(secondary_color),
		-- text_color = ToImGuiColor(text_color),
		-- automation_recording = ToImGuiColor(automation_recording),
		red = red,
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

local function SaveAllState()
	reaper.SetProjExtState(0, ext_name, "", "") -- clear existing data
	-- reaper.ShowConsoleMsg("\n\nclearing existing data...")
	for track_ref, entry in pairs(all_snapshot) do
		local value = entry.show_tcp .. ";" .. entry.show_mcp
		reaper.SetProjExtState(0, ext_name, entry.guid, value)
		-- reaper.ShowConsoleMsg("\nsaving data for GUID: " .. entry.guid .. ", value: " .. value)
	end
end

local function CaptureAllState(clear)
	if clear then
		all_snapshot = {}
	end
	for i = 0, reaper.CountTracks(0) - 1 do
		local track_ref = reaper.GetTrack(0, i)
		if all_snapshot[track_ref] == nil then
			local show_tcp = reaper.GetMediaTrackInfo_Value(track_ref, "B_SHOWINTCP")
			local show_mcp = reaper.GetMediaTrackInfo_Value(track_ref, "B_SHOWINMIXER")
			local _, guid = reaper.GetSetMediaTrackInfo_String(track_ref, "GUID", "", false)
			all_snapshot[track_ref] = { show_tcp = show_tcp, show_mcp = show_mcp, guid = guid }
		end
	end
	SaveAllState()
end

local function ShowHideTrack(track_ref, show)
	local saved = all_snapshot[track_ref]
	local has_data = saved ~= nil
	if show then
		if saved then
			reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINTCP", saved.show_tcp)
			reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINMIXER", saved.show_mcp)
		else --NOTE: fallback for no snapshot data
			reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINTCP", 1)
			reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINMIXER", 1)
			local _, guid = reaper.GetSetMediaTrackInfo_String(track_ref, "GUID", "", false)
			all_snapshot[track_ref] = { show_tcp = 1, show_mcp = 1, guid = guid }
		end
	else -- hide
		reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINTCP", 0)
		reaper.SetMediaTrackInfo_Value(track_ref, "B_SHOWINMIXER", 0)
	end
	return has_data
end

local function RestoreAllState()
	local save_after = false
	for i = 0, reaper.CountTracks(0) - 1 do
		local track_ref = reaper.GetTrack(0, i)
		local is_pinned = reaper.GetMediaTrackInfo_Value(track_ref, "B_TCPPIN") == 1
		if not show_pinned or not is_pinned then
			-- NOTE: pinned tracks are left untouched (not hidden) when show_pinned is off. Maybe revisit later
			local loaded = ShowHideTrack(track_ref, true)
			if not loaded then
				save_after = true
			end
		end
	end
	if save_after then
		SaveAllState()
	end
	reaper.TrackList_AdjustWindows(false) -- actually show changes
	focused_main_tracks = {}
	focused_pinned_tracks = {}
	UnsoloAll()
end

-- MAIN LIST
local function TrackPrefix(track)
	local indent_str = string.rep("    ", track.depth)
	local folder_str = ""
	if track.is_folder then
		folder_str = track.is_collapsed and "▸ " or "▾ "
	end
	return indent_str .. folder_str
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
			ShowHideTrack(track_ref, true)
			if should_solo then
				reaper.SetMediaTrackInfo_Value(track_ref, "I_SOLO", 1)
			end
		else
			ShowHideTrack(track_ref, false)
			if should_solo then
				reaper.SetMediaTrackInfo_Value(track_ref, "I_SOLO", 0)
			end
		end
	end
	reaper.TrackList_AdjustWindows(false) -- actually show changes
end

local function PassesSelectFilters(track_ref)
	if not show_mcp_only_tracks and IsMCPOnly(track_ref) then
		return false
	end
	if not show_hidden_tracks and IsArchived(track_ref) then
		return false
	end
	return true
end

local function PassesDisplayFilters(track)
	if not PassesSelectFilters(track.track_ref) then
		return false
	end
	if only_folder_parents and not track.is_folder then
		return false
	end
	return true
end

local function ToggleFolderChildren(track, set, add)
	local depth_to_select = track.depth + 1
	local current_depth = depth_to_select
	for i = track.number, reaper.CountTracks(0) - 1 do
		local other_track_ref = reaper.GetTrack(0, i)
		local folder_depth_state = reaper.GetMediaTrackInfo_Value(other_track_ref, "I_FOLDERDEPTH")

		if add then
			if PassesSelectFilters(other_track_ref) then
				set[other_track_ref] = true
			end
		else
			set[other_track_ref] = nil
		end

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

local function HandleMainTrackClick(track)
	local mods = ImGui.GetKeyMods(ctx)
	local ctrl_held = (mods & ImGui.Mod_Ctrl) ~= 0
	local alt_held = (mods & ImGui.Mod_Alt) ~= 0
	local should_solo = alt_held or solo_selected

	if last_alt_click and not alt_held then
		UnsoloAll()
	end

	if ctrl_held then -- multi-select
		if focused_main_tracks[track.track_ref] then -- already selected
			focused_main_tracks[track.track_ref] = nil -- unselect it
		else
			if show_pinned and NoFocusedPinnedTracks() then
				AddPinnedTracks()
			end
			focused_main_tracks[track.track_ref] = true -- select it
			if track.is_folder then
				ToggleFolderChildren(track, focused_main_tracks, true)
			end -- and select children, if folder
		end
		last_main_click_ref = nil
	else -- single select
		if track.track_ref == last_main_click_ref then -- if single-select clicked the same track
			focused_main_tracks = {} -- or to restore ALL state later
			last_main_click_ref = nil
		else
			if show_pinned and NoFocusedPinnedTracks() then
				AddPinnedTracks()
			end
			focused_main_tracks = { [track.track_ref] = true } -- single out clicked tracks
			if track.is_folder then
				ToggleFolderChildren(track, focused_main_tracks, true)
			end -- and select children, if folder
			last_main_click_ref = track.track_ref
		end
	end

	if NoFocusedMainTracks() and (show_pinned or NoFocusedPinnedTracks()) then
		RestoreAllState()
	else
		FocusSelected(should_solo)
	end

	last_alt_click = alt_held
end

local function HandlePinnedTrackClick(track)
	local mods = ImGui.GetKeyMods(ctx)
	local alt_held = (mods & ImGui.Mod_Alt) ~= 0
	local should_solo = alt_held or solo_selected

	if focused_pinned_tracks[track.track_ref] then
		focused_pinned_tracks[track.track_ref] = nil
		if NoFocusedPinnedTracks() then
			show_pinned = false
		end
		if NoFocusedMainTracks() and show_pinned then
			RestoreAllState()
			return
		end
	else
		focused_pinned_tracks[track.track_ref] = true
	end

	if IsInAllState() then
		RestoreAllState()
	else
		FocusSelected(should_solo)
	end
end

local function CountVisiblePinnedTracks()
	local count = 0
	for _, pinned_track in ipairs(pinned_tracks) do
		if IsVisible(pinned_track) then
			count = count + 1
		end
	end
	return count
end

local function ShowHideAllInSet(set, show)
	for _, track in ipairs(set) do
		ShowHideTrack(track.track_ref, show)
	end
end

local function HandleShowPinnedToggle() -- TODO: implement show/hide toggle for each track, or pinned track visibility are completely independent from focus? ==> selected = visible
	local total = #pinned_tracks
	if total == 0 then
		return
	end -- nothing to do

	if IsInAllState() then
		local visible_count = CountVisiblePinnedTracks()
		if visible_count == total and not show_pinned then -- all pinned are visible
			ShowHideAllInSet(pinned_tracks, false) -- hide all pinned
		elseif visible_count == 0 and show_pinned then -- no pinned are visible
			ShowHideAllInSet(pinned_tracks, true) -- show all pinned
		end
		reaper.TrackList_AdjustWindows(false)
	else -- something is focused
		local focused_count = CountKeys(focused_pinned_tracks)
		if focused_count == total and not show_pinned then -- all pinned are focused
			focused_pinned_tracks = {} -- unselect all pinned
			FocusSelected(solo_selected)
		elseif focused_count == 0 and show_pinned then -- no pinned are focused
			AddPinnedTracks() -- add all pinned
			FocusSelected(solo_selected)
		end
	end
end

local function HandleAllButtonClick()
	if show_pinned and NoFocusedPinnedTracks() then
		for _, pinned_track in ipairs(focused_pinned_tracks) do
			ShowHideTrack(pinned_track, true) -- show all pinned
		end
	end
	RestoreAllState()
end

local function HandleNavClick(track) -- TODO: if already soloed? unsolo
	local mods = ImGui.GetKeyMods(ctx)
	local ctrl_held = (mods & ImGui.Mod_Ctrl) ~= 0
	local alt_held = (mods & ImGui.Mod_Alt) ~= 0
	local should_solo = alt_held or solo_selected

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

	--? needs last alt?
	reaper.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view
end

-- Q: EDGE CASE when folder parent is pinned, but children are not (REAPER behavior) --> collapse in main somehow?
local function SetupTrackListTableColumns()
	ImGui.TableSetupColumn(ctx, "Track #", ImGui.TableColumnFlags_WidthFixed)
	ImGui.TableSetupColumn(ctx, "Name", ImGui.TableColumnFlags_WidthStretch)
end

local function RenderTrackListRow(entry, focused_set, is_pinned)
	ImGui.TableNextRow(ctx)

	if ImGui.TableSetColumnIndex(ctx, 0) then
		local is_soloed = reaper.GetMediaTrackInfo_Value(entry.track_ref, "I_SOLO") ~= 0
		local number_color = is_soloed and Theme_colors.red or 0xFFFFFFFF -- TODO: use theme text color
		ImGui.PushStyleColor(ctx, ImGui.Col_Text, SetAlpha(number_color, 0.5))
		ImGui.Text(ctx, tostring(entry.number))
		ImGui.PopStyleColor(ctx, 1)
	end

	if ImGui.TableSetColumnIndex(ctx, 1) then
		local retval = ImGui.Selectable(
			ctx,
			TrackPrefix(entry) .. entry.name,
			IsEntrySelected(entry, focused_set),
			ImGui.SelectableFlags_SpanAllColumns | ImGui.SelectableFlags_AllowOverlap
		)
		if retval then
			if not focus_view then
				HandleNavClick(entry)
			else
				if is_pinned then
					HandlePinnedTrackClick(entry)
				else
					HandleMainTrackClick(entry)
				end
			end
		end
	end
end

local function RenderTrackListTable(table_id, set, focused_set, is_pinned)
	local table_flags = not is_pinned and ImGui.TableFlags_ScrollY or nil
	if not ImGui.BeginTable(ctx, table_id, 2, table_flags) then
		return
	end

	SetupTrackListTableColumns()

	local skip_depth = nil

	for _, entry in ipairs(set) do
		local parent_is_collapsed = not is_pinned and skip_depth ~= nil and entry.depth >= skip_depth

		if not parent_is_collapsed and PassesDisplayFilters(entry) then
			RenderTrackListRow(entry, focused_set, is_pinned)
		end

		if not is_pinned and not parent_is_collapsed then
			skip_depth = nil
			if entry.is_folder and entry.is_collapsed then
				skip_depth = entry.depth + 1
			end
		end
	end

	ImGui.EndTable(ctx)
end

local function InitAllState() -- default all to show all
	for i = 0, reaper.CountTracks(0) - 1 do
		local track_ref = reaper.GetTrack(0, i)
		local _, guid = reaper.GetSetMediaTrackInfo_String(track_ref, "GUID", "", false)
		all_snapshot[track_ref] = { show_tcp = 1, show_mcp = 1, guid = guid }
	end
end

local function LoadOrInitAllState()
	all_snapshot = {}
	focused_main_tracks = {}
	focused_pinned_tracks = {}

	GatherAllTrackInfo()

	local loaded_data_entries = 0
	for _, entry in ipairs(pinned_tracks) do
		loaded_data_entries = loaded_data_entries + ReadProjStoredState(entry)
	end
	for _, entry in ipairs(main_tracks) do
		loaded_data_entries = loaded_data_entries + ReadProjStoredState(entry)
	end

	local track_count = reaper.CountTracks(0)
	if loaded_data_entries == track_count then
		no_saved_data = false
	elseif loaded_data_entries == 0 then
		InitAllState()
		no_saved_data = true
	else
		CaptureAllState(false)
		no_saved_data = false
	end
end

local function CheckProjectChanged()
	local current_project = reaper.EnumProjects(-1)
	local project_changed = current_project ~= last_known_project
	if project_changed then
		last_known_project = current_project
	end
	return project_changed
end

--==============================================================
local function loop()
	ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, 2)
	ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 8, 8)

	ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, Theme_colors.bg_color)
	ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg, Theme_colors.bg_color)
	ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive, Theme_colors.bg2_color)
	ImGui.PushStyleColor(ctx, ImGui.Col_DockingPreview, SetAlpha(Theme_colors.primary_color, 0.7))
	ImGui.PushStyleColor(ctx, ImGui.Col_DockingEmptyBg, Theme_colors.bg2_color)

	local window_flags = ImGui.WindowFlags_NoCollapse
	local visible, open = ImGui.Begin(ctx, "Track Compass", true, window_flags)

	ImGui.PopStyleVar(ctx, 2)
	ImGui.PopStyleColor(ctx, 5)

	if visible then
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 2)
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding, 1)
		ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize, 1)

		local mode_color = focus_view and Lighten(Theme_colors.primary_color, 0.1) or Theme_colors.primary_color

		ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered, SetAlpha(Lighten(Theme_colors.bg2_color, 0.15), 0.8))
		ImGui.PushStyleColor(ctx, ImGui.Col_TabSelected, mode_color)
		ImGui.PushStyleColor(ctx, ImGui.Col_TabSelectedOverline, Theme_colors.primary_color)
		ImGui.PushStyleColor(ctx, ImGui.Col_Tab, SetAlpha(Theme_colors.bg2_color, 0.45))
		ImGui.PushStyleColor(ctx, ImGui.Col_TabDimmed, SetAlpha(Darken(Theme_colors.bg2_color, 0.2), 0.98))
		ImGui.PushStyleColor(ctx, ImGui.Col_TabDimmedSelected, SetAlpha(Theme_colors.bg2_color, 0.3))
		ImGui.PushStyleColor(ctx, ImGui.Col_TabDimmedSelectedOverline, SetAlpha(Theme_colors.primary_color, 0))

		ImGui.PushStyleColor(ctx, ImGui.Col_Border, SetAlpha(Lighten(Theme_colors.primary_color, 0.2), 0.2))
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
		ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarGrab, SetAlpha(Theme_colors.primary_color, 0.5))
		ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarGrabActive, SetAlpha(Theme_colors.primary_color, 0.7))
		ImGui.PushStyleColor(
			ctx,
			ImGui.Col_ScrollbarGrabHovered,
			SetAlpha(Lighten(Theme_colors.primary_color, 0.15), 1)
		)

		if ImGui.BeginTabBar(ctx, "##tabs") then
			if CheckProjectChanged() then
				LoadOrInitAllState()
			end

			------------------------------- TRACK LIST TAB
			if ImGui.BeginTabItem(ctx, "Track list") then
				--------------------------- WINDOW SIZING
				local NUM_BELOW_ELEMENTS = 4
				local footer_height = ImGui.GetFrameHeightWithSpacing(ctx) * NUM_BELOW_ELEMENTS
				local list_height = -footer_height

				local available_width = ImGui.GetContentRegionAvail(ctx)

				----------------------------- LIST BOX / TABLE
				ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, SetAlpha(Theme_colors.bg2_color, 1)) -- list box, checkbox bg
				-- -FLT_MIN = right align
				if ImGui.BeginChild(ctx, "##tracklist", -FLT_MIN, list_height, ImGui.ChildFlags_FrameStyle) then
					GatherAllTrackInfo()
					RenderTrackListTable("##pinnedtracklist", pinned_tracks, focused_pinned_tracks, true) --TODO: or optionally display all pinned, scroll main
					if next(pinned_tracks) ~= nil then
						ImGui.Separator(ctx)
					end
					RenderTrackListTable("##maintracklist", main_tracks, focused_main_tracks, false)
					ImGui.EndChild(ctx)
				end

				--------------------------- MAIN BUTTONS
				ImGui.PushStyleVarX(ctx, ImGui.StyleVar_ItemSpacing, 2)
				local spacing_x = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
				local capture_button_width = 20

				-- ALL BUTTON
				if ImGui.Button(ctx, "ALL", available_width - capture_button_width - spacing_x, 0) then
					HandleAllButtonClick()
				end
				ImGui.SetItemTooltip(
					ctx,
					"Show all desired tracks.\nThis keeps tracks that are shown in the TCP but not MCP (eg. MIDI only tracks) intact."
				)

				ImGui.SameLine(ctx)

				-- CAPTURE BUTTON
				if no_saved_data then -- red
					ImGui.PushStyleColor(ctx, ImGui.Col_Button, SetAlpha(Theme_colors.red, 0.5))
					ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, Theme_colors.red)
					ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, SetAlpha(Theme_colors.red, 0.67))
				else -- grey
					ImGui.PushStyleColor(ctx, ImGui.Col_Button, SetAlpha(Theme_colors.bg2_color, 0.6))
					ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, Darken(Theme_colors.bg2_color, 0.1))
					ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, SetAlpha(Theme_colors.bg2_color, 0.8))
				end

				if ImGui.Button(ctx, "*", capture_button_width, 0) then
					CaptureAllState(true)
				end
				ImGui.SetItemTooltip(
					ctx,
					no_saved_data
							and "No saved data for this project yet.\nClick to capture current state as the default state (ALL).\nIf you have tracks that are shown in the TCP but not MCP (eg. MIDI only tracks), this will keep that intact"
						or "Update default project state (ALL)"
				)

				ImGui.PopStyleColor(ctx, 3)
				ImGui.PopStyleVar(ctx, 1)

				------------------------------ OPTIONS CHECKBOXES
				-- FOCUS VIEW
				local focus_changed, focus_new = ImGui.Checkbox(ctx, "Focus view", focus_view)
				if focus_changed then
					focus_view = focus_new
					SaveBoolState("focus_view", focus_view)
					if not focus_view then
						RestoreAllState()
					end
				end
				ImGui.SetItemTooltip(ctx, "Show only selected tracks in Arrange view and Mixer")

				-- SOLO SELECTED
				local solo_selected_change, solo_selected_new = ImGui.Checkbox(ctx, "Solo", solo_selected)
				if solo_selected_change then
					solo_selected = solo_selected_new
					if not solo_selected_new then
						UnsoloAll()
					end
				end
				ImGui.SetItemTooltip(ctx, "Exclusively solo selected tracks")

				-- KEEP PINNED
				local show_pinned_change, show_pinned_new = ImGui.Checkbox(ctx, "Show pinned tracks", show_pinned)
				if show_pinned_change then
					show_pinned = show_pinned_new
					SaveBoolState("show_pinned", show_pinned) -- TODO: derive on open
					HandleShowPinnedToggle()
				end
				ImGui.SetItemTooltip(ctx, "Show pinned tracks while focusing")

				ImGui.PopStyleColor(ctx, 1)

				ImGui.EndTabItem(ctx)
			end -- tab item
			------------------------------- OPTIONS TAB
			if ImGui.BeginTabItem(ctx, "Options") then
				-- SHOW MCP-only
				local show_mcp_only_tracks_change, show_mcp_only_tracks_new =
					ImGui.Checkbox(ctx, "Show MCP-only", show_mcp_only_tracks)
				if show_mcp_only_tracks_change then
					show_mcp_only_tracks = show_mcp_only_tracks_new
					SaveBoolState("show_mcp_only_tracks", show_mcp_only_tracks)
				end
				ImGui.SetItemTooltip(ctx, "Show tracks with only the MCP (eg. FX return tracks) in the track list")

				-- SHOW HIDDEN
				local show_hidden_tracks_change, show_hidden_tracks_new =
					ImGui.Checkbox(ctx, "Show hidden", show_hidden_tracks)
				if show_hidden_tracks_change then
					show_hidden_tracks = show_hidden_tracks_new
					SaveBoolState("show_hidden_tracks", show_hidden_tracks)
				end
				ImGui.SetItemTooltip(ctx, "Show hidden tracks in track list")

				-- ONLY SHOW FOLDERS
				local only_folder_parents_change, only_folders_parents_new =
					ImGui.Checkbox(ctx, "Only folders", only_folder_parents)
				if only_folder_parents_change then
					only_folder_parents = only_folders_parents_new
					SaveBoolState("only_folder_parents", only_folder_parents)
				end
				ImGui.SetItemTooltip(ctx, "Show only folder parents in track list")

				ImGui.Spacing(ctx) -- TODO: how to stretch until bottom?

				if ImGui.Button(ctx, "Adapt to current theme", -FLT_MIN) then
					CaptureCurrentTheme()
				end

				ImGui.EndTabItem(ctx)
			end
			ImGui.EndTabBar(ctx)
		end -- tab bar
		ImGui.PopStyleVar(ctx, 1) -- frame border
		---------------------

		ImGui.PopStyleVar(ctx, 3)
		ImGui.PopStyleColor(ctx, 26)

		ImGui.End(ctx)
	end -- if visible
	if open then
		reaper.defer(loop)
	end
end

local function Init()
	CaptureCurrentTheme()
	focus_view = LoadBoolState("focus_view", focus_view)
	show_pinned = LoadBoolState("show_pinned", show_pinned)
	show_mcp_only_tracks = LoadBoolState("show_mcp_only_tracks", show_mcp_only_tracks)
	show_hidden_tracks = LoadBoolState("show_hidden_tracks", show_hidden_tracks)
	only_folder_parents = LoadBoolState("only_folder_parents", only_folder_parents)
	LoadOrInitAllState()
end

Init()
reaper.defer(loop)
