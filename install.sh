#!/usr/bin/env bash
# Installe les dotfiles : mac (zsh, MacPorts ou Homebrew), Windows (Git Bash, Scoop) ou Linux/WSL (apt).
# Usage : ./install.sh [--packages]
# Workspace : ~/workspaces (mac, Linux/WSL) ou C:/workspaces (Windows), avec pro/ et perso/. Surcharge : WORKSPACE=D:/dev
# WSL : le workspace vit dans le système de fichiers Linux (~/workspaces), pas sous /mnt/c (bien plus rapide).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PACKAGES=0; [ "${1:-}" = "--packages" ] && INSTALL_PACKAGES=1
IS_WSL=0

case "$(uname -s)" in
  Darwin)               OS=mac;     RC="$HOME/.zshrc"; WS="${WORKSPACE:-$HOME/workspaces}"; WS_SH="$WS" ;;
  Linux)                OS=linux;   WS="${WORKSPACE:-$HOME/workspaces}"; WS_SH="$WS"
                        grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1
                        case "${SHELL##*/}" in zsh) RC="$HOME/.zshrc" ;; *) RC="$HOME/.bashrc" ;; esac ;;
  MINGW*|MSYS*|CYGWIN*) OS=windows; RC="$HOME/.bashrc"; DIR="$(cd "$DIR" && pwd -W)"
                        WS="${WORKSPACE:-C:/workspaces}"; WS_SH="/$(echo "${WS%%:*}" | tr A-Z a-z)${WS#*:}" ;;  # C:/x -> /c/x
  *) echo "OS non supporté: $(uname -s)" >&2; exit 1 ;;
esac
PRO_DIR="${PRO_DIR:-$WS/pro}"   # chemin natif (C:/... sous Windows), lu par git

# --- Git : ~/.gitconfig = includes vers le repo (le dernier gagne) ---
TARGET="$HOME/.gitconfig"
if [ -f "$TARGET" ] && ! grep -q "dotfiles-managed" "$TARGET"; then
  cp "$TARGET" "$TARGET.bak.$(date +%Y%m%d%H%M%S)"; echo "Ancien .gitconfig sauvegardé."
fi
WSL_INC=""; [ "$IS_WSL" = 1 ] && WSL_INC="	path = $DIR/git/gitconfig.wsl"
cat > "$TARGET" <<CFG
# dotfiles-managed : généré par install.sh, ne pas éditer (modifier le repo).
[include]
	path = $DIR/git/gitconfig
	path = $DIR/git/gitconfig.$OS
$WSL_INC
	path = $DIR/git/gitconfig.perso
# Identité de travail : uniquement pour les repos sous $PRO_DIR
[includeIf "gitdir/i:$PRO_DIR/"]
	path = ~/.gitconfig.work
# Réglages propres à cette machine (non versionnés)
[include]
	path = ~/.gitconfig.local
CFG
if [ ! -f "$HOME/.gitconfig.work" ]; then
  cp "$DIR/git/gitconfig.work.example" "$HOME/.gitconfig.work"
  echo ">> Renseignez votre identité pro dans ~/.gitconfig.work"
fi
mkdir -p "$WS_SH/pro" "$WS_SH/perso"

# --- Hook anti-secrets (si le repo est un dépôt git) ---
if [ -d "$DIR/.git" ]; then git -C "$DIR" config core.hooksPath hooks; fi

# --- Règles IA : ai/rules.md -> Claude Code et opencode (sans écraser l'existant) ---
link_rule() {
  [ -e "$2" ] && { echo "Déjà présent, ignoré : $2"; return; }
  mkdir -p "$(dirname "$2")"
  if [ "$OS" = windows ]; then cp "$DIR/ai/rules.md" "$2"; else ln -s "$DIR/ai/rules.md" "$2"; fi
}
link_rule x "$HOME/.claude/CLAUDE.md"
link_rule x "$HOME/.config/opencode/AGENTS.md"

# --- Shell ---
touch "$RC"
# Limite : la recherche textuelle (grep) compte aussi une ligne commentée contenant le chemin comme présence.
add_source() {
  if [ "$OS" = windows ]; then
    # Même fichier sous C:/... ou /c/... (casse libre) : déjà présent, pas de doublon
    local alt="$1"
    case "$1" in ?:/*) alt="/$(echo "${1%%:*}" | tr A-Z a-z)${1#*:}" ;; esac
    grep -qiF -- "$1" "$RC" && return 0
    grep -qiF -- "$alt" "$RC" && return 0
  else
    grep -qF "$1" "$RC" && return 0
  fi
  printf '\n# dotfiles\n[ -f "%s" ] && . "%s"\n' "$1" "$1" >> "$RC"
}
grep -q "^export WORKSPACE=" "$RC" || printf '\n# dotfiles\nexport WORKSPACE="%s"\n' "$WS_SH" >> "$RC"
add_source "$DIR/shell/git_aliases.sh"
add_source "$DIR/shell/dev_aliases.sh"
add_source "$DIR/shell/jetbrains_path.sh"
[ "$OS" = windows ] && add_source "$DIR/shell/bash_prompt.sh"

# --- VS Code (pas sous Linux/WSL : les réglages sont gérés côté Windows, via Remote - WSL) ---
if [ "$OS" = mac ]; then VSC="$HOME/Library/Application Support/Code/User"; else VSC="${APPDATA:-}/Code/User"; fi
if [ "$OS" != linux ] && [ -d "$(dirname "$VSC")" ]; then
  mkdir -p "$VSC"
  [ -f "$VSC/settings.json" ] && [ ! -L "$VSC/settings.json" ] && cp "$VSC/settings.json" "$VSC/settings.json.bak"
  if [ "$OS" = mac ]; then ln -sf "$DIR/vscode/settings.json" "$VSC/settings.json"
  else cp "$DIR/vscode/settings.json" "$VSC/settings.json"; fi
  if command -v code >/dev/null; then
    grep -v '^#' "$DIR/vscode/extensions.txt" | while read -r e; do [ -n "$e" ] && { code --install-extension "$e" --force >/dev/null 2>&1 || echo "Extension ignorée (échec) : $e" >&2; }; done
  fi
fi

# --- Paquets (opt-in : --packages) ---
if [ "$INSTALL_PACKAGES" = 1 ]; then
  if [ "$OS" = windows ]; then
    if command -v scoop >/dev/null; then
      grep -v '^#' "$DIR/packages/scoop.txt" | sed '/^$/d' | while read -r k v; do
        if [ "$k" = bucket ]; then scoop bucket add "$v" || true; else scoop install "$k" || true; fi
      done
    else
      echo "Scoop absent. Dans PowerShell (sans admin) : irm get.scoop.sh | iex   puis relancez --packages" >&2
    fi
  elif [ "$OS" = linux ]; then
    if command -v apt-get >/dev/null; then
      grep -v '^#' "$DIR/packages/apt.txt" | sed '/^$/d' | xargs sudo apt-get install -y
    else
      echo "apt-get absent : installez à la main les paquets de packages/apt.txt." >&2
    fi
  elif command -v brew >/dev/null; then
    brew bundle --file="$DIR/packages/Brewfile"
  elif command -v port >/dev/null; then
    grep -v '^#' "$DIR/packages/macports.txt" | sed '/^$/d' | while read -r l; do sudo port install $l; done
  else
    echo "Ni Homebrew ni MacPorts détecté." >&2
  fi
fi

echo "OK ($OS) : $TARGET et $RC configurés."
[ "$RC" = "$HOME/.zshrc" ] && echo "Zsh : sourcez shell/zsh_setup.zsh avant oh-my-zsh et shell/zsh_plugins_end.zsh en dernière ligne de ~/.zshrc."
[ "$IS_WSL" = 1 ] && echo "WSL : ajoutez votre clé SSH dans ce WSL (~/.ssh, ssh/config.example) ; Git Credential Manager doit être installé côté Windows."
exit 0
