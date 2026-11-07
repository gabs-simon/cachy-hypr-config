-- Window rules wiki https://wiki.hypr.land/Configuring/Basics/Window-Rules/

--------------------------------------------------------------------------------
-- Helpers
--
-- Every helper takes a `match`, which can be:
--   * a string                -> treated as a class pattern, e.g. "^(heroic)$"
--   * a match table           -> e.g. { class = "^(steam)$", title = "^(Friends List)$" }
--   * a list of the above     -> e.g. { "^(foo)$", { title = "^(Bar)$" } }
-- Most helpers also take an optional `extra` table of rule props, merged on top.
--------------------------------------------------------------------------------

local GAMING_WORKSPACE = "name:gaming"

-- Shallow-merge any number of tables (later ones win, nil args are skipped).
local function merge(...)
    local out = {}
    for i = 1, select("#", ...) do
        local t = select(i, ...)
        if t then
            for k, v in pairs(t) do out[k] = v end
        end
    end
    return out
end

-- Call `fn` once per match table, normalizing strings and lists.
local function each_match(match, fn)
    if type(match) == "string" then
        fn({ class = match })
    elseif match[1] ~= nil then
        for _, m in ipairs(match) do each_match(m, fn) end
    else
        fn(match)
    end
end

-- Size relative to the monitor's long (w) and short (h) side,
-- so it behaves the same on landscape and portrait monitors.
local function scaled(w, h)
    return {
        ("max(monitor_w, monitor_h)*%.2f"):format(w),
        ("min(monitor_w, monitor_h)*%.2f"):format(h),
    }
end

-- Plain rule: apply `props` to every match.
local function rule(match, props)
    each_match(match, function(m)
        hl.window_rule(merge(props, { match = m }))
    end)
end

-- Games: sent to the gaming workspace and forced borderless fullscreen.
-- Windows with no title yet, or whose initial title is a Wine path
-- (e.g. Z:\home\...), are left alone so splash/loader windows don't get resized.
local function game(match)
    each_match(match, function(m)
        hl.window_rule({ match = m, workspace = GAMING_WORKSPACE })
        hl.window_rule({
            match = merge({
                title         = "^(.+)$",
                initial_title = "negative:^(.*\\\\home\\\\.*)$",
            }, m),
            content          = "game",
            decorate         = false,
            fullscreen_state = 2,
            size             = { "monitor_w", "monitor_h" },
            sync_fullscreen  = true,
        })
    end)
end

-- Floating windows (utilities, dialogs, small tools).
local function floating(match, extra)
    rule(match, merge({ float = true }, extra))
end

-- Launchers: float on the primary monitor.
local function launcher(match, extra)
    rule(match, merge({ float = true, monitor = PRIMARY_MONITOR }, extra))
end

-- Background apps (chat, store, etc.) that live on a fixed workspace of the side monitor.
local function side_app(match, workspace, extra)
    rule(match, merge({ monitor = MONITOR3, workspace = workspace }, extra))
end

-- Undo the game() rules for non-game windows that share a game's class
-- (e.g. Wine launchers that also get `steam_app_default`). Must come after the game() rules.
local function not_game(match, extra)
    rule(match, merge({
        content          = "none",
        decorate         = true,
        fullscreen       = false,
        fullscreen_state = 0,
    }, extra))
end

-- Force full opacity (media, browsers, apps that handle their own transparency).
local function opaque(match)
    rule(match, { opacity = "1.0 override" })
end

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------

-- Generic floating position
rule({ float = true }, { center = true })

-- Picture-in-Picture
floating({ title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, {
    keep_aspect_ratio = true,
    size              = scaled(0.25, 0.25),
    pin               = true,
})

--------------------------------------------------------------------------------
-- Gaming
--------------------------------------------------------------------------------

rule({ content = "game" }, { workspace = GAMING_WORKSPACE })

game({
    "^(steam_app.*)$",
    "^(gamescope)$",
})

-- World of Warcraft (retail + classic) through Wine/Lutris/Battle.net
game({
    "^([Ww]ow([Cc]lassic)?\\.exe)$",
    { title = "^(World of Warcraft)$" },
})


-- Steam client popups
floating({ class = "^(steam)$", title = "^(Friends List)$" })
floating({ class = "^(steam)$", title = "^(Launching\\.{3})$" }, { center = true, workspace = GAMING_WORKSPACE })

-- Steam games that open an untitled window first (splash / pre-launcher): keep it floating
floating({ class = "^(steam_app.*)$", initial_title = "^$" }, {
    center           = true,
    fullscreen       = false,
    fullscreen_state = 0,
    workspace        = GAMING_WORKSPACE,
})

launcher("^([Bb]attle\\.net\\.exe)$")

-- Battle.net (Lutris/Wine gives it the same `steam_app_default` class as its games)
-- Main client lives next to Steam; its popups ("Battle.net Settings", ...) float.
not_game({ class = "^(steam_app.*)$", title = "^(Battle\\.net.*)$" }, { monitor = MONITOR3, workspace = "7" })
not_game({ class = "^(steam_app.*)$", title = "^(Battle\\.net .+)$" }, { float = true, center = true, size = scaled(0.52, 0.83) })

--------------------------------------------------------------------------------
-- Apps
--------------------------------------------------------------------------------

-- Wine / Proton floating windows
rule({ class = "^(.*\\.exe)$", float = true }, { monitor = PRIMARY_MONITOR, center = true, fullscreen_state = 0 })

launcher("^(.*[Ll]auncher.*)$")

side_app({ class = "^(steam)$", title = "negative:^(Launching\\.{3})$" }, "7")
side_app("^(vesktop|discord)$", "8")
side_app("^(org\\.telegram\\.desktop|TelegramDesktop|telegram-desktop)$", "9")

floating("^(.*[Cc]alc.*)$", { size = scaled(0.17, 0.43) })
floating("^(org\\.kde\\.keditfiletype)$")
rule("^(org\\.kde\\.ark)$", { size = scaled(0.40, 0.40) })
floating({ class = "^(.*satty.*)$", title = "^(Satty)$" }, { min_size = scaled(0.35, 0.35) })
floating("^(dev\\.)?(noctalia\\.Noctalia(\\.Settings)?)$", { size = { "monitor_w*0.70", "monitor_h*0.70" } })

-- Dolphin: float and open under the cursor (except its progress/config dialogs)
floating({
    class = "^(org\\.kde\\.dolphin)$",
    title = "negative:^(Moving.*|Create New.*|Extract.*|Compress.*|Copying.*|Progress.*|Configure.*|Properties.*|Choose\\sApplication.*)$",
}, {
    size = scaled(0.50, 0.55),
    move = {
        "max(20, min(cursor_x - (window_w*0.50), monitor_w - window_w + 20))", -- X axis clamping
        "max(20, min(cursor_y - 50, monitor_h - window_h + 20))", -- Y axis clamping
    },
})

-- Exiled Exchange
rule("^(exiled-exchange-2)$", { name = "exiled-exchange", no_blur = true })

--------------------------------------------------------------------------------
-- Opacity Overrides
--------------------------------------------------------------------------------

opaque({
    "^(firefox|zen)$",
    -- Terminals: defer to the terminal's own opacity setting. Remove if your terminal doesn't support transparency.
    "^(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)$",
    "^(mpv|org.kde.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$",
})

--------------------------------------------------------------------------------
-- Float Utility Windows
--------------------------------------------------------------------------------

floating({
    "^(kvantummanager|qt[56]ct|nwg-look)$",
    "^(org.pulseaudio.pavucontrol|blueman-manager|nm-applet|nm-connection-editor)$",
    { title = "^(Winetricks.*|Protontricks.*)$" },
})

--------------------------------------------------------------------------------
-- Float Common Modals
--------------------------------------------------------------------------------

floating({
    { title = "^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$" },
    { initial_title = "^(Open File)$" },
    "^([Xx]dg-desktop-portal-gtk)$",
    { title = "^(File Upload|Choose wallpaper|Library)(.*)$" },
    "^(.*dialog.*)$",
    { title = "^(.*dialog.*)$" },
    "^(hyprland-share-picker)$",
})

--------------------------------------------------------------------------------
-- Fixes
--------------------------------------------------------------------------------

-- Ignore maximize requests from all apps. You'll probably like this.
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
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
