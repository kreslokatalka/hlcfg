
-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

hl.on("hyprland.start", function ()
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("/home/kreslo/.config/themes/start-waybar.sh")
  hl.exec_cmd("swaync")

  -- Launch apps; window rules place them on their assigned workspaces.
  hl.exec_cmd("firefox")
  hl.exec_cmd("codium")
  hl.exec_cmd("obsidian")
  hl.exec_cmd("Telegram")
  hl.exec_cmd("happ")

  --hl.exec_once("xrandr --output DP-1 --primary")
end)
