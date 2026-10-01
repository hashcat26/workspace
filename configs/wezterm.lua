local wezterm = require "wezterm"
local config = wezterm.config_builder()

local function bind_key(keys, hotkey, arguments)
    local root = os.getenv("WORKSPACE_ROOT")

    keys[#keys + 1] = {
        key = hotkey, mods = "CTRL",
        action = wezterm.action.SpawnCommandInNewTab{args = arguments, cwd = root}
    }

    keys[#keys + 1] = {
        key = hotkey, mods = "ALT",
        action = wezterm.action.SpawnCommandInNewWindow{args = arguments}
    }
end


wezterm.on("gui-startup", function()
    local tab, pane, window = wezterm.mux.spawn_window{}
    window:gui_window():maximize()
end)

wezterm.on("update-status", function(window, pane)
    local selection = window:get_selection_text_for_pane(pane)
    local directory = pane:get_current_working_dir()
    local title = pane:get_title()
    local process = pane:get_foreground_process_info()

    local console_title =
        selection ~= ""
        and utf8.len(selection) .. " characters currently selected"
        or (directory and directory.file_path:gsub("^/", "") or title)

    local active_process =
        "wezterm:" .. wezterm.procinfo.pid()
        .. " " .. (process and process.name:lower():gsub("%.exe$", "") or "N/A")
        .. ":" .. (process and process.pid or "N/A")

    local mods, leds = window:keyboard_modifiers()
    local caps_lock_state = leds:find("CAPS_LOCK") ~= nil
    local num_lock_state = leds:find("NUM_LOCK") ~= nil

    window:set_left_status(
        wezterm.format{
            {Foreground = {Color = "#FFFFFF"}},
            {Text = console_title}
        }
    )

    window:set_right_status(
        wezterm.format{
            {Foreground = {Color = "#FFFFFF"}},
            {Text = active_process .. " "},

            {Foreground = {Color = caps_lock_state and "#FFFFFF" or "#666666"}},
            {Text = "CAPS" .. " "},

            {Foreground = {Color = num_lock_state and "#FFFFFF" or "#666666"}},
            {Text = "NUM" .. " "},

            {Foreground = {Color = "#FFFFFF"}},
            {Text = wezterm.strftime("%H:%M:%S")}
        }
    )
end)


config.keys = {
    {key = "p", mods = "CTRL|SHIFT", action = wezterm.action.ShowLauncher},
    {key = "v", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard")},
    {key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentPane{confirm = false}},

    {
        key = "r", mods = "CTRL|SHIFT", action = wezterm.action.Multiple{
            wezterm.action.ReloadConfiguration,
            wezterm.action.SendString("\x01\x0b source $nu.config-path; clear \r")
        }
    }
}

config.mouse_bindings = {
    {event = {Up = {streak = 1, button = "Left"}}, mods = "CTRL", action = wezterm.action.OpenLinkAtMouseCursor},

    {
        event = {Up = {streak = 1, button = "Left"}}, mods = "NONE", action = wezterm.action.Multiple{
            wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
            wezterm.action.ClearSelection
        }
    }
}

bind_key(config.keys, "t", {"cmd"})
bind_key(config.keys, "p", {"powershell"})
bind_key(config.keys, "b", {"bash", "--login"})
bind_key(config.keys, "n", {"nu", "--login"})


config.default_prog = {"nu"}
config.default_cwd = os.getenv("WORKSPACE_ROOT")

config.animation_fps = 60
config.status_update_interval = 100

config.color_scheme = "Dark Pastel"
config.window_background_opacity = 0.80

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.show_tabs_in_tab_bar = false
config.show_new_tab_button_in_tab_bar = false

config.font = wezterm.font("Fira Code")
config.font_size = 11.00

config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.cursor_blink_rate = 400

config.enable_kitty_keyboard = true
config.check_for_updates = false

return config
