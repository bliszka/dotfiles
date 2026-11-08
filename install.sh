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
for pkg in stow git; do
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

# --- 5. tmux plugins (TPM) ----------------------------------------------------

step "5. tmux plugins"
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

# --- 6. Files kept out of git -----------------------------------------------

step "6. Files kept out of git"
if [[ -f $DOTFILES/vault/intelephense-license.txt ]]; then
  ok "vault/intelephense-license.txt"
else
  warn "vault/intelephense-license.txt is missing - copy it from a backup"
fi

# --- 7. Reload ----------------------------------------------------------------

if ! $CHECK; then
  step "7. Reload"
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
