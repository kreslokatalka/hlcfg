
---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "rofi -show drun"
local locker      = "hyprlock"


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("/home/kreslo/.config/waybar/launch.sh"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("/home/kreslo/.config/themes/open-gallery.sh"))

-- Lock the screen (SUPER + L)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(locker))
--hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
--hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + S",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + D", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)


-- hl.bind(mainMod .. " + C",         hl.dsp.workspace.toggle_special("Code"))
-- hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.move({ workspace = "special:Code" }))

hl.bind(mainMod .. " + M",         hl.dsp.workspace.toggle_special("music"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.window.move({ workspace = "special:music" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Audio controls: SHIFT+F1 mutes, SHIFT+F2 lowers by 5%, SHIFT+F3 raises by 5%.
local audioMute = hl.dsp.exec_cmd("/home/kreslo/.config/hypr/scripts/audio-volume.sh mute")
local audioDown = hl.dsp.exec_cmd("/home/kreslo/.config/hypr/scripts/audio-volume.sh down")
local audioUp   = hl.dsp.exec_cmd("/home/kreslo/.config/hypr/scripts/audio-volume.sh up")

hl.bind("SHIFT + F1", audioMute, { locked = true, repeating = false })
hl.bind("SHIFT + F2", audioDown, { locked = true, repeating = true })
hl.bind("SHIFT + F3", audioUp,   { locked = true, repeating = true })

hl.bind("PRINT", function()
    hl.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")
end)
---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us, ru",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:caps_toggle",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})
