# Hyprland Configuration

Personal Hyprland configuration written in Lua. The main entry point loads the settings in `config/`, applies personal keyboard settings from `gabs/keyboard.lua`, and applies the Noctalia-generated theme.

## Requirements

- Hyprland with the Lua configuration runtime/API used by this setup
- Noctalia, used for the theme and several keybinding commands
- UWSM, unless the application launch prefix in `config/binds.lua` is changed
- The applications configured in `config/variables.lua` for their corresponding launcher shortcuts

The keybindings and rules also call tools such as `hyprctl`, `hyprpicker`, `btop`, and `xhost`. Install the tools for the features you use. `dbus-update-activation-environment` is called during startup.

## Install

Place this repository at `~/.config/hypr` and start or reload Hyprland. The entry point is `hyprland.lua`.

If you do not use UWSM, edit `launchPrefix` near the top of `config/binds.lua` to an empty string. Update the app names in `config/variables.lua` to match the programs installed on your system. Noctalia commands can be changed or removed in `config/binds.lua` and `config/autostart.lua` if you use a different desktop shell.

## Configuration Layout

| Path | Purpose |
| --- | --- |
| `hyprland.lua` | Loads the Lua configuration modules and applies the Noctalia theme |
| `config/animations.lua` | Animation curves and presets |
| `config/autostart.lua` | Startup commands and initial monitor check |
| `config/binds.lua` | Window management, application, hardware, and workspace keybindings |
| `config/colors.lua` | CachyOS-inspired color constants |
| `config/decorations.lua` | Gaps, borders, opacity, rounding, and blur |
| `config/environment.lua` | Optional environment variable settings |
| `config/inputs.lua` | Pointer, gesture, and input settings |
| `config/misc.lua` | General Hyprland behavior |
| `config/monitors.lua` | Connector discovery, monitor layout, lid behavior, and hotplug updates |
| `config/variables.lua` | Default applications and workspace count |
| `config/windowrules.lua` | Application-specific window rules |
| `config/workspaces.lua` | Workspace assignment by monitor and laptop/desktop mode |
| `gabs/keyboard.lua` | Personal keyboard layout and options |
| `noctalia.lua` | Noctalia-generated theme values and application function |
| `hyprtoolkit.conf` | Hyprtoolkit color theme |
| `xdph.conf` | XDG Desktop Portal Hyprland settings |

`workspaces.conf` is currently empty; workspace rules are defined in `config/workspaces.lua`.

## Monitor Setup

`config/monitors.lua` detects connected outputs from `/sys/class/drm` and matches them by connector prefix, so connector numbers can change without changing the configured roles. If detection fails, it falls back to the last-known connector names in that file.

The current layout is tailored to a laptop and three external displays:

| Output role | Connector type | Resolution / refresh | Position |
| --- | --- | --- | --- |
| Left external | DisplayPort (`DP-`) | 1920x1080 at 75 Hz | `0x0` |
| Center external | HDMI (`HDMI-A-`) | 1920x1080 at 144 Hz | `1920x0` |
| Right external | DVI (`DVI-I-`) | 1920x1080 at 75 Hz | `3840x0` |
| Built-in display | eDP (`eDP-`) | 1920x1080 at 144 Hz | Below center, or `0x0` in notebook mode |

Edit `check_monitor_mode()` in `config/monitors.lua` to change modes or positions. The internal display is disabled when the lid is closed. Monitor additions and removals trigger a layout refresh.

## Customization

- Change default applications in `config/variables.lua`.
- Change keybindings and the UWSM launch prefix in `config/binds.lua`.
- Change workspace assignments in `config/workspaces.lua`.
- Change window matching rules in `config/windowrules.lua`.
- Change input, animation, color, decoration, and general behavior in their corresponding `config/*.lua` modules.
- Keep modules loaded before the modules that consume their globals when editing the `require` sequence in `hyprland.lua`.