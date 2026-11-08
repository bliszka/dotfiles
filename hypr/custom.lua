-- My Hyprland settings on top of Omarchy's defaults.
--
-- This file lives in ~/dotfiles. ~/.config/hypr/hyprland.lua loads it with a
-- few lines at its end (install.sh adds them), so these settings win:
--   local my_hypr = os.getenv("HOME") .. "/dotfiles/hypr/custom.lua"
--   ...dofile(my_hypr)
-- Omarchy updates and `omarchy refresh hyprland` may reset hyprland.lua.
-- Run ~/dotfiles/install.sh to add the lines again.

-- Monitor ---------------------------------------------------------------------
-- iiyama G-Master GCB3481WQSU-B1 (EDID name PL3481WQ), 34", 21:9, VA.
-- Matched by its description, not the port, so the rule follows the monitor
-- from HDMI to DisplayPort and does nothing on other computers.
-- Native panel is 3440x1440. Over HDMI the EDID offers at most 100 Hz.
-- The panel does 180 Hz over DisplayPort (DP 1.4): after switching the cable,
-- change mode to "3440x1440@180" (check `hyprctl monitors all` for the exact rate).
-- 3840x2160 is a 16:9 input mode the monitor downscales - do not use it.
-- cm = "edid" stays off: with it Chrome and Brave dim pages.
hl.monitor({
  output = "desc:iiyama Corporation PL3481WQ 1242543710552",
  mode = "3440x1440@99.98",
  position = "auto",
  scale = 1,
})

-- GTK draws its own UI at this whole-number factor (X11/XWayland apps too).
-- Monitor scale is 1, so keep GTK at 1. Restart an app for a change to apply.
hl.env("GDK_SCALE", "1")

-- Keyboard --------------------------------------------------------------------
-- Toggle dictation with Super+Ctrl+X ("ctrl+opt+x" on my keyboard) - the
-- binding from before Omarchy 4.5 made Alt+Space the default. I use this one.
-- F9 push-to-talk from the same old block is not used, so it stays out.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
end

-- Layout ----------------------------------------------------------------------
-- A lone window on the ultrawide stays centered at 16:9 instead of spanning
-- the full 3440 px width.
hl.config({
  layout = {
    single_window_aspect_ratio = { 16, 9 },
  },
})

-- Windows ---------------------------------------------------------------------
-- Active windows fully opaque, inactive 0.98. Overrides Omarchy's "0.985 0.96",
-- which let a light wallpaper show through Ghostty.
o.window(".*", { opacity = "1 0.98" })

-- These apps always open fullscreen (Ghostty grid at fullscreen: 382x72 cells).
o.window("^(com\\.mitchellh\\.ghostty|kitty|TradingView)$", { fullscreen = true })
