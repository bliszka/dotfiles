-- My monitor settings. They override ~/.config/hypr/monitors.lua, which stays
-- the Omarchy default so updates and `omarchy refresh hyprland` can change it
-- freely.
--
-- This file lives in ~/dotfiles (stow package "hypr"). Hyprland loads it
-- through one line in ~/.config/hypr/hyprland.lua, right after
-- require("hypr.monitors"):
--   require("default.hypr.require_optional").module("hypr.monitors-custom")
-- If a refresh resets hyprland.lua, add that line again.

-- iiyama G-Master GCB3481WQSU-B1 (EDID name PL3481WQ), 34", 21:9, VA.
-- Native panel is 3440x1440. The EDID "preferred" mode is only 60 Hz; over
-- HDMI the panel supports 100 Hz at native resolution.
-- 3840x2160 is a 16:9 input mode the monitor downscales - do not use it.
--
-- The panel is wide-gamut (EDID primaries close to DCI-P3). cm = "edid" makes
-- Hyprland map sRGB content to those primaries instead of stretching it.
-- cm = "edid" is OFF (2026-11-07): after an OSD reset the default sRGB preset
-- looks good, and with "edid" Chrome and Brave dim pages (Wayland color
-- management). To use it again, add cm = "edid" and start Chrome/Brave with
-- --disable-features=WaylandWpColorManagerV1.
hl.monitor({ output = "HDMI-A-1", mode = "3440x1440@99.98", position = "auto", scale = 1 })

-- GTK draws its own UI at this whole-number factor (X11/XWayland apps too).
-- Monitor scale is 1, so keep GTK at 1. Restart an app for a change to apply.
hl.env("GDK_SCALE", "1")
