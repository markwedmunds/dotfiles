local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

config.color_scheme = "Gruvbox dark, hard (base16)"
config.font = wezterm.font("JetBrainsMono Nerd Font")
-- disable ligatures (top-level; per-font harfbuzz_features is unreliable)
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.font_size = 14.0
config.line_height = 1.2
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

-- let alt compose special characters instead of acting as a meta key
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

wezterm.on("toggle-terminal", function(window, pane)
	local tab = window:active_tab()
	local panes = tab:panes()

	if #panes == 1 then
		-- only one pane, so split
		pane:split({ direction = "Bottom", size = 0.2 })
	else
		-- multiple panes, close current one
		window:perform_action(act.CloseCurrentPane({ confirm = false }), pane)
	end
end)

config.keys = {
	{
		key = "q",
		mods = "CMD",
		action = act.CloseCurrentPane({ confirm = false }),
	},
	{
		key = "d",
		mods = "CMD",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "d",
		mods = "CMD|SHIFT",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "t",
		mods = "CMD",
		action = act.EmitEvent("toggle-terminal"),
	},
	{
		key = "k",
		mods = "CMD",
		action = act.SendString("clear\n"),
	},
}

return config
