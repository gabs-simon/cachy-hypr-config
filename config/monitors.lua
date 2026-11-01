-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = "MONITOR1",
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })
hl.monitor({
    output    = MONITOR1,
    mode      = "1920x1080@75",
    position  = "0x0",
    scale     = "1",
})
hl.monitor({
    output    = MONITOR2,
    mode      = "1920x1080@144",
    position  = "1920x0",
    scale     = "1",
})
hl.monitor({
    output    = MONITOR3,
    mode      = "1920x1080@75",
    position  = "3840x0",
    scale     = "1",
})
if not is_lid_open() then
    hl.monitor({ output = BUILTIN_MONITOR, disabled = true })
elseif CURRENT_MONITOR_MODE == DESKTOP_MODE then
    hl.monitor({
        output    = BUILTIN_MONITOR,
        mode      = "1920x1080@144",
        position  = "1920x1080",
        scale     = "1.0",
    })
else
    hl.monitor({
        output    = BUILTIN_MONITOR,
        mode      = "1920x1080@144",
        position  = "0x0",
        scale     = "1.0",
    })
end