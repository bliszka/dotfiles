#!/usr/bin/env bash
# Put my settings on top of a fresh (or reinstalled) Omarchy.
#
#   ~/dotfiles/install.sh           apply everything that is missing
#   ~/dotfiles/install.sh --check   only report what is missing, change nothing
#
# Safe to run again: every step checks first and changes only what is missing.
#
# Pattern: Omarchy owns its config files and may change them on updates.
# My settings live in this repo, and one include line in each Omarchy file
# loads them straight from ~/dotfiles. `omarchy refresh ...` or a migration
# can drop an include line - run this script again to add it back.
# Neovim is the exception: Omarchy leaves it to the user, so the whole
# config is linked with GNU stow.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
CHECK=false
MISSING=0

case "${1:-}" in
  --check) CHECK=true ;;
  "") ;;
  *) echo "Usage: $0 [--check]" >&2; exit 2 ;;
esac

if [[ $DOTFILES != "$HOME/dotfiles" ]]; then
  echo "This repo must be at ~/dotfiles (the include lines point there)." >&2
  exit 1
fi

# --- My choices (edit here) -------------------------------------------------

# Packages from the Arch and Omarchy repositories.
PACKAGES=(stow git superwhisper-bin)

# Omarchy shell plugins installed from git: "<plugin-id> <git-url>".
SHELL_PLUGINS=(
  "io.github.johnsideserf.ultrawide-background https://github.com/johnsideserf/omarchy-ultrawide-background"
)

# Ultrawide background pack for the monitor (3440x1440 = 21x9).
ULTRAWIDE_RATIO="21x9"

# System monospace font (the Omarchy default). The Omarchy menu
# Install > Style > Font switches every terminal and the bar to another font.
FONT="JetBrainsMono Nerd Font"

# Theme and background. The background file comes from the ultrawide pack.
THEME="catppuccin"
BACKGROUND="$HOME/.config/omarchy/backgrounds/catppuccin/winding-road.jpg"

# --- Helpers ----------------------------------------------------------------

ok()    { printf '  \e[32mok\e[0m      %s\n' "$*"; }
todo()  { printf '  \e[33mmissing\e[0m %s\n' "$*"; MISSING=$((MISSING + 1)); }
done_() { printf '  \e[36mdone\e[0m    %s\n' "$*"; }
warn()  { printf '  \e[31mwarning\e[0m %s\n' "$*"; }
step()  { printf '\n\e[1m%s\e[0m\n' "$*"; }
short() { printf '%s' "${1/#$HOME/\~}"; }

# Copy a file to <file>.bak.<date> before changing it. Never overwrites an
# existing backup: adds -2, -3... instead. Sets BACKUP to the new name.
backup() {
  local n=2
  BACKUP="$1.bak.$STAMP"
  while [[ -e $BACKUP ]]; do BACKUP="$1.bak.$STAMP-$n"; n=$((n + 1)); done
  cp -p "$1" "$BACKUP"
}

# Rewrite a file in place from stdin. cat > keeps owner, mode and inode.
rewrite() {
  local tmp
  tmp="$(mktemp)"
  cat >"$tmp"
  cat "$tmp" >"$1"
  rm -f "$tmp"
}

# ensure_include FILE NEEDLE BLOCK
# Appends BLOCK to FILE unless a line already contains NEEDLE.
ensure_include() {
  local file="$1" needle="$2" block="$3"

  if [[ ! -f $file ]]; then
    warn "$(short "$file") does not exist - is Omarchy installed?"
    return
  fi
  if grep -qF -- "$needle" "$file"; then
    ok "$(short "$file") loads my file"
    return
  fi
  if $CHECK; then
    todo "$(short "$file"): include line"
    return
  fi
  backup "$file"
  { cat "$file"; printf '\n%s\n' "$block"; } | rewrite "$file"
  done_ "$(short "$file"): include line added (backup: $(basename "$BACKUP"))"
}

# --- 1. Packages ------------------------------------------------------------

step "1. Packages"
for pkg in "${PACKAGES[@]}"; do
  if pacman -Q "$pkg" &>/dev/null; then ok "$pkg"
  elif $CHECK; then todo "$pkg"
  else omarchy pkg add "$pkg" && done_ "$pkg installed"
  fi
done

# --- 2. Include lines in Omarchy files --------------------------------------

step "2. Include lines in Omarchy files"

ensure_include "$HOME/.config/hypr/hyprland.lua" \
  'dotfiles/hypr/custom.lua' \
  '-- My own settings from ~/dotfiles/hypr/custom.lua (monitor, window opacity).
-- Loaded last, so they win. Skipped if the file is missing.
local my_hypr = os.getenv("HOME") .. "/dotfiles/hypr/custom.lua"
local my_hypr_file = io.open(my_hypr, "r")
if my_hypr_file then
  my_hypr_file:close()
  dofile(my_hypr)
end'

ensure_include "$HOME/.config/ghostty/config" \
  'dotfiles/ghostty/config-custom' \
  '# My own settings from ~/dotfiles. Loaded after this file, so its values win.
# Skipped if the file is missing.
config-file = ?"~/dotfiles/ghostty/config-custom"'

ensure_include "$HOME/.config/tmux/tmux.conf" \
  'dotfiles/tmux/tmux-custom.conf' \
  '# My own settings from ~/dotfiles. Loaded last, so they win.
source-file -q ~/dotfiles/tmux/tmux-custom.conf'

ensure_include "$HOME/.bashrc" \
  'dotfiles/bash/bashrc-custom' \
  '# My own settings from ~/dotfiles.
[[ -f ~/dotfiles/bash/bashrc-custom ]] && source ~/dotfiles/bash/bashrc-custom'

# --- 3. Chromium flags --------------------------------------------------------

step "3. Chromium flags"
flags_file="$HOME/.config/chromium-flags.conf"
if [[ -L $flags_file ]]; then
  warn "$(short "$flags_file") is a symlink - replace it with Omarchy's file: omarchy refresh chromium"
elif [[ ! -f $flags_file ]]; then
  warn "$(short "$flags_file") does not exist - is Omarchy installed?"
else
  added=()
  while IFS= read -r flag; do
    [[ -z $flag || $flag == \#* ]] && continue
    if grep -qxF -- "$flag" "$flags_file"; then
      ok "${flag%%=*}"
    elif $CHECK; then
      todo "${flag%%=*}"
    else
      added+=("$flag")
    fi
  done <"$DOTFILES/chromium/flags-custom"
  if ((${#added[@]})); then
    backup "$flags_file"
    { cat "$flags_file"; printf '%s\n' "${added[@]}"; } | rewrite "$flags_file"
    for flag in "${added[@]}"; do done_ "${flag%%=*} added"; done
    warn "restart Chromium to use the new flags"
  fi
fi

# --- 4. Neovim (stow) ---------------------------------------------------------

step "4. Neovim config (stow)"
nvim_target="$HOME/.config/nvim"
nvim_source="$DOTFILES/nvim/.config/nvim"
if [[ $(readlink -f "$nvim_target" 2>/dev/null) == "$(readlink -f "$nvim_source")" ]]; then
  ok "~/.config/nvim -> dotfiles/nvim"
elif $CHECK; then
  todo "~/.config/nvim is not linked to dotfiles/nvim"
else
  if [[ -e $nvim_target || -L $nvim_target ]]; then
    mv "$nvim_target" "$nvim_target.bak.$STAMP"
    done_ "Omarchy's nvim config moved aside to nvim.bak.$STAMP"
  fi
  stow --dir="$DOTFILES" --target="$HOME" --restow nvim
  done_ "~/.config/nvim linked to dotfiles/nvim"
fi

# --- 5. Omarchy shell plugins, theme and background ---------------------------

step "5. Omarchy shell plugins, theme and background"
shell_json="$HOME/.config/omarchy/shell.json"
plugin_dir="$HOME/.config/omarchy/plugins"

# Is plugin <id> on the enabled list in shell.json?
plugin_enabled() {
  jq -e --arg id "$1" '(.plugins // []) | map(.id) | index($id) != null' "$shell_json" &>/dev/null
}

for entry in "${SHELL_PLUGINS[@]}"; do
  read -r id url <<<"$entry"
  if [[ -d $plugin_dir/$id ]] && plugin_enabled "$id"; then
    ok "plugin $id"
  elif $CHECK; then
    todo "plugin $id (installed and enabled)"
  elif [[ -d $plugin_dir/$id ]]; then
    omarchy plugin enable "$id" >/dev/null && done_ "plugin $id enabled"
  else
    omarchy plugin add "$url" --enable --yes >/dev/null && done_ "plugin $id installed and enabled"
  fi
done

# Ultrawide background pack (images, ~550 MB download on the first install).
uw_cli="$plugin_dir/io.github.johnsideserf.ultrawide-background/bin/omarchy-ultrawide"
if [[ -x $uw_cli ]]; then
  # Read the whole output first: `| grep -q` would stop early, the CLI would get
  # SIGPIPE and pipefail would turn a match into a failure.
  uw_status="$("$uw_cli" status 2>/dev/null || true)"
  if [[ $uw_status == *"ratio=$ULTRAWIDE_RATIO "* || $uw_status == *"ratio=$ULTRAWIDE_RATIO"$'\n'* ]]; then
    ok "ultrawide background pack $ULTRAWIDE_RATIO"
  elif $CHECK; then
    todo "ultrawide background pack $ULTRAWIDE_RATIO"
  else
    "$(dirname "$uw_cli")/../install.sh" "$ULTRAWIDE_RATIO" >/dev/null &&
      done_ "ultrawide background pack $ULTRAWIDE_RATIO installed"
  fi
elif ! $CHECK; then
  warn "ultrawide plugin is missing - background pack skipped"
fi

# Superwhisper bar panel. Superwhisper links its panel plugin on first start.
if jq -e '[.bar.layout[]?[]?.id] | index("superwhisper.panel") != null' "$shell_json" &>/dev/null; then
  ok "Superwhisper panel in the bar"
elif $CHECK; then
  todo "Superwhisper panel in the bar"
elif [[ -e $plugin_dir/superwhisper-panel ]]; then
  omarchy bar put superwhisper.panel --after omarchy.tray >/dev/null && done_ "Superwhisper panel added to the bar"
else
  warn "start Superwhisper once (it adds its bar plugin), then run this script again"
fi

# Theme, then background (applying a theme resets the background).
current_theme="$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)"
if [[ $current_theme == "$THEME" ]]; then
  ok "theme $THEME"
elif $CHECK; then
  todo "theme $THEME (now: ${current_theme:-none})"
else
  omarchy theme set "$THEME" >/dev/null && done_ "theme $THEME applied"
fi

current_bg="$(readlink -f "$HOME/.local/state/omarchy/current/background" 2>/dev/null || true)"
if [[ $current_bg == "$(readlink -f "$BACKGROUND")" ]]; then
  ok "background $(basename "$BACKGROUND")"
elif $CHECK; then
  todo "background $(basename "$BACKGROUND") (now: $(basename "${current_bg:-none}"))"
elif [[ -f $BACKGROUND ]]; then
  omarchy theme bg set "$BACKGROUND" >/dev/null && done_ "background $(basename "$BACKGROUND") set"
else
  warn "$(short "$BACKGROUND") not found - install the ultrawide pack first"
fi

# System font: the font fontconfig gives for "monospace" (bar, Qt apps) and
# the font Ghostty really uses (after config-custom).
mono_font="$(fc-match monospace family 2>/dev/null | cut -d, -f1)"
ghostty_font="$(ghostty +show-config 2>/dev/null | sed -n 's/^font-family = //p' | head -1)"
if [[ $mono_font == "$FONT" && $ghostty_font == "$FONT" ]]; then
  ok "font $FONT"
elif $CHECK; then
  todo "font $FONT (now: monospace=$mono_font, Ghostty=$ghostty_font)"
else
  omarchy font set "$FONT" >/dev/null 2>&1
  # `omarchy font set` also writes ~/.config/fontconfig/fonts.conf. When
  # Omarchy's own default already gives $FONT, drop that override file.
  fc_user="$HOME/.config/fontconfig/fonts.conf"
  if [[ -f $fc_user ]]; then
    mv "$fc_user" "$fc_user.off"
    if [[ $(fc-match monospace family | cut -d, -f1) == "$FONT" ]]; then
      rm -f "$fc_user.off"
    else
      mv "$fc_user.off" "$fc_user"
    fi
  fi
  done_ "font $FONT set (terminals and bar)"
fi

# --- 6. tmux plugins (TPM) ----------------------------------------------------

step "6. tmux plugins"
tpm="$HOME/.config/tmux/plugins/tpm"
if [[ -d $tpm ]]; then
  ok "TPM"
elif $CHECK; then
  todo "TPM (~/.config/tmux/plugins/tpm)"
else
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm"
  done_ "TPM cloned"
fi
if ! $CHECK && [[ -x $tpm/bin/install_plugins ]]; then
  if tmux info &>/dev/null; then
    "$tpm/bin/install_plugins" >/dev/null && done_ "tmux plugins installed"
  else
    warn "tmux is not running - start it and press prefix + I to install plugins"
  fi
fi

# --- 7. Files kept out of git -----------------------------------------------

step "7. Files kept out of git"
if [[ -f $DOTFILES/vault/intelephense-license.txt ]]; then
  ok "vault/intelephense-license.txt"
else
  warn "vault/intelephense-license.txt is missing - copy it from a backup"
fi

# --- 8. Reload ----------------------------------------------------------------

if ! $CHECK; then
  step "8. Reload"
  if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null; then
    hyprctl reload >/dev/null
    errors="$(hyprctl configerrors 2>/dev/null || true)"
    if [[ -z ${errors//[[:space:]]/} ]]; then done_ "Hyprland reloaded"
    else warn "Hyprland config errors:"; echo "$errors"
    fi
  fi
  if tmux info &>/dev/null; then
    tmux source-file "$HOME/.config/tmux/tmux.conf" && done_ "tmux reloaded"
  fi
  done_ "Ghostty and bash: open a new window to see the changes"
fi

echo
if $CHECK; then
  if ((MISSING == 0)); then echo "Everything is in place."; else echo "$MISSING item(s) missing. Run: $0"; fi
  exit $((MISSING > 0))
fi
echo "Finished."
