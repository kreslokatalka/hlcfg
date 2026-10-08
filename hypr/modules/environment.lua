-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
-----------------------
hl.env("GDK_BACKEND", "wayland,x11,*") -- GTK: Use Wayland if available; if not, try X11 and then any other GDK backend.
hl.env("QT_QPA_PLATFORM", "wayland;xcb") -- Qt: Use Wayland if available, fall back to X11 if not.
hl.env("SDL_VIDEODRIVER", "wayland") -- Run SDL2 applications on Wayland. Remove or set to x11 if games that provide older versions of SDL cause compatibility issues.
hl.env("CLUTTER_BACKEND", "wayland") -- Clutter package already has Wayland enabled, this variable will force Clutter applications to try and use the Wayland backend.
-- Qt

    hl.env("QT_QPA_PLATFORMTHEME", "gtk3") -- Use the installed GTK platform theme for Qt applications.
    hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1") -- (From the Qt documentation) enables automatic scaling, based on the monitor’s pixel density.
    hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1") -- Disables window decorations on Qt applications.