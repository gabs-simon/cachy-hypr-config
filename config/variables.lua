-- Hyprland default apps

TERMINAL     = "kitty"
FILE_MANAGER = "nemo"
BROWSER      = "vivaldi"
EDITOR       = "code"
CALCULATOR   = "gnome-calculator"
NVIM         = "nvim"

-- Monitors
--
-- Connector indices (DP-12 vs DP-13, HDMI-A-1 vs HDMI-A-2, ...) can change
-- across reboots/cable reseats. Instead of hardcoding an index, detect the
-- currently connected outputs and match by connector type prefix, falling
-- back to the last-known-good name if detection fails.
--
-- NOTE: this reads /sys/class/drm directly instead of calling `hyprctl`.
-- Calling `hyprctl` here would make Hyprland's own IPC socket answer a
-- request from within the config parse that spawned it, i.e. the main
-- thread would block waiting on itself until a timeout kicks in - that's
-- what caused the multi-second freeze on every config reload.

function get_connected_monitor_names()
    local names = {}
    local handle = io.popen("ls -1 /sys/class/drm 2>/dev/null")
    if not handle then return names end
    local entries = handle:read("*a")
    handle:close()

    for entry in entries:gmatch("[^\r\n]+") do
        local connector = entry:match("^card%d+%-(.+)$")
        if connector then
            local status_file = io.open("/sys/class/drm/" .. entry .. "/status", "r")
            if status_file then
                local status = status_file:read("*l")
                status_file:close()
                if status == "connected" then
                    table.insert(names, connector)
                end
            end
        end
    end
    return names
end

function find_by_prefix(names, prefix, fallback)
    for _, name in ipairs(names) do
        if name:sub(1, #prefix) == prefix then
            return name
        end
    end
    return fallback
end

function find_monitor_by_index(ind)
    if ind == 0 then
            return find_by_prefix(connected_monitors, "eDP-", "eDP-2")
    end if ind == 1 then
            return find_by_prefix(connected_monitors, "DP-", "DP-13")
    end if ind == 2 then
            return find_by_prefix(connected_monitors, "HDMI-A-", "HDMI-A-1")
    end if ind == 3 then
            return find_by_prefix(connected_monitors, "DVI-I-", "DVI-I-1")
    end
    return nil
end

local connected_monitors = get_connected_monitor_names()

MONITOR1 = find_by_prefix(connected_monitors, "DP-", "DP-13")
MONITOR2 = find_by_prefix(connected_monitors, "HDMI-A-", "HDMI-A-1")
MONITOR3 = find_by_prefix(connected_monitors, "DVI-I-", "DVI-I-1")
BUILTIN_MONITOR = find_by_prefix(connected_monitors, "eDP-", "eDP-2")
PRIMARY_MONITOR = MONITOR2

-- Workspaces
NUM_WPM = 3 -- Number of workspaces per monitor (Max 10)

NOTEBOOK_MODE = "notebook"
DESKTOP_MODE = "desktop"

function has_external_monitor()
    for _, name in ipairs(connected_monitors) do
        if not name:match("^eDP%-") then
            return true
        end
    end
    return false
end

function current_monitor_mode()
    return has_external_monitor() and DESKTOP_MODE or NOTEBOOK_MODE
end

CURRENT_MONITOR_MODE = has_external_monitor() and DESKTOP_MODE or NOTEBOOK_MODE

function is_lid_open()
    local f = io.open("/proc/acpi/button/lid/LID0/state", "r")
    if not f then return true end -- no lid switch present, assume desktop
    local content = f:read("*a")
    f:close()
    return content:find("open") ~= nil
end

local function is_connected(name)
    for _, connected_name in ipairs(connected_monitors) do
        if connected_name == name then return true end
    end
    return false
end

local function configure_external_monitor(name, mode, position)
    if is_connected(name) then
        hl.monitor({ output = name, mode = mode, position = position, scale = "1" })
    end
end

function check_monitor_mode(lock_notebook_on_closed_lid)
    connected_monitors = get_connected_monitor_names()
    MONITOR1 = find_by_prefix(connected_monitors, "DP-", "DP-13")
    MONITOR2 = find_by_prefix(connected_monitors, "HDMI-A-", "HDMI-A-1")
    MONITOR3 = find_by_prefix(connected_monitors, "DVI-I-", "DVI-I-1")
    BUILTIN_MONITOR = find_by_prefix(connected_monitors, "eDP-", "eDP-2")
    PRIMARY_MONITOR = MONITOR2

    CURRENT_MONITOR_MODE = has_external_monitor() and DESKTOP_MODE or NOTEBOOK_MODE

    configure_external_monitor(MONITOR1, "1920x1080@75", "0x0")
    configure_external_monitor(MONITOR2, "1920x1080@144", "1920x0")
    configure_external_monitor(MONITOR3, "1920x1080@75", "3840x0")

    if is_connected(BUILTIN_MONITOR) then
        if not is_lid_open() then
            hl.monitor({ output = BUILTIN_MONITOR, disabled = true })
            if CURRENT_MONITOR_MODE == NOTEBOOK_MODE and lock_notebook_on_closed_lid then
                hl.exec_cmd("noctalia msg session lock")
            end
        elseif CURRENT_MONITOR_MODE == DESKTOP_MODE then
            hl.monitor({ output = BUILTIN_MONITOR, mode = "1920x1080@144", position = "1920x1080", scale = "1" })
        else
            hl.monitor({ output = BUILTIN_MONITOR, mode = "1920x1080@144", position = "0x0", scale = "1" })
        end
    end
end

hl.on("monitor.added", function ()
    check_monitor_mode()
end)

hl.on("monitor.removed", function ()
    check_monitor_mode()
end)