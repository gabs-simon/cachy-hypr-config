-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Add your workspace rules here. Increment the workspace number as you go. Do not have duplicate workspaces.

local function refresh_workspace()
  connected_monitors = get_connected_monitor_names()
  MONITOR1 = find_by_prefix(connected_monitors, "DP-", "DP-13")
  MONITOR2 = find_by_prefix(connected_monitors, "HDMI-A-", "HDMI-A-1")
  MONITOR3 = find_by_prefix(connected_monitors, "DVI-I-", "DVI-I-1")
  BUILTIN_MONITOR = find_by_prefix(connected_monitors, "eDP-", "eDP-2")

  if current_monitor_mode() == NOTEBOOK_MODE then
    hl.workspace_rule({ workspace = "name:gaming", monitor = BUILTIN_MONITOR, default = true })
    hl.workspace_rule({ workspace = "1", monitor = BUILTIN_MONITOR, persistent = true })
    hl.workspace_rule({ workspace = "2", monitor = BUILTIN_MONITOR, persistent = true })
    hl.workspace_rule({ workspace = "3", monitor = BUILTIN_MONITOR, persistent = true })
  else
    hl.workspace_rule({ workspace = "name:gaming", monitor = MONITOR2, default = true })
    hl.workspace_rule({ workspace = "1", monitor = MONITOR1, persistent = true })
    hl.workspace_rule({ workspace = "2", monitor = MONITOR1, persistent = true })
    hl.workspace_rule({ workspace = "3", monitor = MONITOR1, persistent = true })
    hl.workspace_rule({ workspace = "4", monitor = MONITOR2, persistent = true })
    hl.workspace_rule({ workspace = "5", monitor = MONITOR2, persistent = true })
    hl.workspace_rule({ workspace = "6", monitor = MONITOR2, persistent = true })
    hl.workspace_rule({ workspace = "7", monitor = MONITOR3, persistent = true })
    hl.workspace_rule({ workspace = "8", monitor = MONITOR3, persistent = true })
    hl.workspace_rule({ workspace = "9", monitor = MONITOR3, persistent = true })

    hl.workspace_rule({ workspace = "10", monitor = BUILTIN_MONITOR, persistent = true })
    hl.workspace_rule({ workspace = "11", monitor = BUILTIN_MONITOR, persistent = true })
    hl.workspace_rule({ workspace = "12", monitor = BUILTIN_MONITOR, persistent = true })
  
  end
end

refresh_workspace()

hl.on("monitor.added", function ()
    refresh_workspace()
end)

hl.on("monitor.removed", function ()
    refresh_workspace()
end)