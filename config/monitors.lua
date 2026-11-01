-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Connector indices can change across reboots or cable reseats, so detect
-- connected outputs by connector type and fall back to their last-known names.
-- Read /sys/class/drm directly; querying hyprctl during config parsing can block
-- Hyprland's main thread waiting on its own IPC socket.

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

-- In my personal setup, I use three external monitors and the built-in display.
-- - eDP is the built-in laptop display, positioned below the center monitor
-- - DP is the first external monitor, positioned on the left
-- - HDMI is the second external monitor, positioned on the center
-- - DVI is the third external monitor, positioned on the right
function find_monitor_by_index(ind)
    if ind == 0 then
        return find_by_prefix(connected_monitors, "eDP-", "eDP-2")
    elseif ind == 1 then
        return find_by_prefix(connected_monitors, "DP-", "DP-13")
    elseif ind == 2 then
        return find_by_prefix(connected_monitors, "HDMI-A-", "HDMI-A-1")
    elseif ind == 3 then
        return find_by_prefix(connected_monitors, "DVI-I-", "DVI-I-1")
    end
    return nil
end

connected_monitors = get_connected_monitor_names()

-- Sometimes plugging the monitors off and on can change connector names;
-- Indexes might change, but connectors stay the same given same USB hub and cables.
-- These helpers ensure we use the correct names based on connector types.
MONITOR1 = find_by_prefix(connected_monitors, "DP-", "DP-13")
MONITOR2 = find_by_prefix(connected_monitors, "HDMI-A-", "HDMI-A-1")
MONITOR3 = find_by_prefix(connected_monitors, "DVI-I-", "DVI-I-1")
BUILTIN_MONITOR = find_by_prefix(connected_monitors, "eDP-", "eDP-2")
PRIMARY_MONITOR = MONITOR2

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
    if not f then return true end
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

function refresh_monitor_config()
    check_monitor_mode()
end

refresh_monitor_config()

hl.on("monitor.added", function ()
    refresh_monitor_config()
end)

hl.on("monitor.removed", function ()
    refresh_monitor_config()
end)