
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

-- Place each application on its assigned workspace.
local app_workspaces = {
    { name = "firefox",   class = "^firefox$",              workspace = "1"  },
    { name = "codium",    class = "^codium$",               workspace = "2"  },
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
