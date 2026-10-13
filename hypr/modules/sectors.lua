
--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Keep the theme picker as the keyboard target while the pointer moves over
-- other windows, like a launcher/menu with persistent focus.
hl.window_rule({
    name  = "theme-gallery-stay-focused",
    match = { class = "^org[.]hyprland[.]theme-gallery$" },

    stay_focused = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Keep selected workspaces on the small monitor (HDMI-A-1).
for _, workspace in ipairs({ "1", "7", "10" }) do
    hl.workspace_rule({
        workspace = workspace,
        monitor   = "HDMI-A-1",
    })
end

-- Keep the remaining workspaces 2-9 on the large monitor (DP-1).
for _, workspace in ipairs({ "2", "3", "4", "5", "6", "8", "9" }) do
    hl.workspace_rule({
        workspace = workspace,
        monitor   = "DP-1",
    })
end

-- Close a Waybar control popover on clicks outside its layer surface without
-- focusing the window underneath. The per-bind non-consuming option by itself
-- does not pass mouse input, so the popover temporarily enables Hyprland's
-- pass_mouse_when_bound setting while it is open.
local function dismissControlPopoverOutsideClick()
    local layers = hl.get_layers({ namespace = "waybar-control-popover" })
    if #layers == 0 then
        return
    end

    local cursor = hl.get_cursor_pos()
    if not cursor then
        return
    end

    for _, layer in ipairs(layers) do
        if cursor.x >= layer.x and cursor.x < layer.x + layer.w
            and cursor.y >= layer.y and cursor.y < layer.y + layer.h then
            return
        end
    end

    hl.exec_cmd("pkill -TERM -x control-popover")
end

for _, button in ipairs({ 272, 273, 274 }) do
    hl.bind("mouse:" .. button, dismissControlPopoverOutsideClick, {
        mouse = true,
        click = true,
        non_consuming = true,
        desc = "Close Waybar control popover outside click",
    })
end

hl.bind("mouse:275", dismissControlPopoverOutsideClick, {
    mouse = true,
    click = true,
    non_consuming = true,
    desc = "Close Waybar control popover outside click",
})

-- Place each application on its assigned workspace.
local app_workspaces = {
    { name = "firefox",   class = "^firefox$",              workspace = "1"  },
    { name = "codium",    class = "^codium$",               workspace = "2"  },
    { name = "code",    class = "^code-oss$",                    workspace = "2"  },
    { name = "obsidian",  class = "^md[.]obsidian[.]Obsidian$", workspace = "3"  },
    { name = "telegram",  class = "^org[.]telegram[.]desktop$", workspace = "4"  },
    { name = "happ",      class = "^Happ$",                 workspace = "10" },
    { name = "steam",      class = "^Steam$",                 workspace = "5" },
}

for _, app in ipairs(app_workspaces) do
    hl.window_rule({
        name  = app.name .. "-workspace",
        match = { class = app.class },
        workspace = app.workspace,
    })
end
