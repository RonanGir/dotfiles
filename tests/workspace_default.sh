#!/usr/bin/env bash
# Test du workspace par défaut : ~/workspaces (mac, Linux/WSL) ou C:/workspaces (Windows), avec pro/ et perso/.
# Partie statique : partout (défauts et chemins écrits dans install.sh, shell/, ai/rules.md, README.md).
# Partie dynamique : mac/Linux/WSL uniquement, dans un HOME temporaire ; install.sh tourne dans une copie
# avec un .git jetable. Sous Windows, la partie dynamique est sautée : C:/workspaces réel n'est jamais touché.
# Arrêt au premier écart (code 1) ; OK en dernière ligne seulement si tout passe.
# Usage : bash tests/workspace_default.sh   (INSTALL_SRC=chemin permet de tester une autre version de install.sh)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${INSTALL_SRC:-$ROOT/install.sh}"
IS_WIN=0
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WIN=1 ;; esac

pass() { echo "ok   : $*"; }
fail() { echo "FAIL : $*" >&2; exit 1; }

# Regex ERE : ancien chemin singulier (~/workspace, $HOME/workspace, C:/workspace) suivi d'un caractère autre que "s"
OLD_RE='(~|[$]HOME|C:)/workspace([^s]|$)'

# $1 = fichier, $2 = chaîne fixe attendue, $3 = libellé
must_have() { grep -qF -- "$2" "$1" && pass "$3" || fail "$3 : \"$2\" absent de $1"; }

# $1 = fichier, $2 = regex ERE interdite, $3 = libellé
must_not_match() {
  local hit
  hit="$(grep -nE -- "$2" "$1" || true)"
  if [ -n "$hit" ]; then fail "$3 : $(printf '%s' "$hit" | head -n 1)"; fi
  pass "$3"
}

# --- Statique ---
must_have "$ROOT/install.sh" 'WS="${WORKSPACE:-$HOME/workspaces}"' "install.sh : défaut mac/Linux ~/workspaces"
must_have "$ROOT/install.sh" 'WS="${WORKSPACE:-C:/workspaces}"' "install.sh : défaut Windows C:/workspaces"
must_have "$ROOT/install.sh" 'PRO_DIR="${PRO_DIR:-$WS/pro}"' "install.sh : sous-dossier pro/"
must_have "$ROOT/install.sh" 'mkdir -p "$WS_SH/pro" "$WS_SH/perso"' "install.sh : création de pro/ et perso/"
must_not_match "$ROOT/install.sh" '[$]WS(_SH)?/work|WORK_DIR' "install.sh : aucun sous-dossier work/"
must_not_match "$ROOT/install.sh" "$OLD_RE" "install.sh : aucun ancien chemin singulier"

must_have "$ROOT/shell/dev_aliases.sh" '${WORKSPACE:-$HOME/workspaces}' "dev_aliases.sh : repli ~/workspaces"
must_not_match "$ROOT/shell/dev_aliases.sh" "$OLD_RE" "dev_aliases.sh : aucun ancien chemin singulier"

must_have "$ROOT/shell/zsh_setup.zsh" '~/workspaces/dotfiles/shell/zsh_setup.zsh' "zsh_setup.zsh : commentaire ~/workspaces"
must_not_match "$ROOT/shell/zsh_setup.zsh" "$OLD_RE" "zsh_setup.zsh : aucun ancien chemin singulier"

must_have "$ROOT/ai/rules.md" '`~/workspaces`' "ai/rules.md : ~/workspaces"
must_have "$ROOT/ai/rules.md" '`C:/workspaces`' "ai/rules.md : C:/workspaces"
must_not_match "$ROOT/ai/rules.md" "$OLD_RE" "ai/rules.md : aucun ancien chemin singulier"

must_have "$ROOT/README.md" 'git clone <url> ~/workspaces/dotfiles' "README.md : chemin de clone ~/workspaces"
must_have "$ROOT/README.md" 'WORKSPACE=~/custom-workspaces ./install.sh' "README.md : exemple de surcharge neutre (custom-workspaces)"
must_not_match "$ROOT/README.md" '(~|[$]HOME|C:)/workspace/' "README.md : aucun ancien chemin singulier avec sous-dossier"
must_not_match "$ROOT/README.md" 'git clone .*~/workspace/dotfiles' "README.md : clone sans ancien chemin"

# --- Dynamique (hors Windows) ---
if [ "$IS_WIN" = 1 ]; then
  echo "skip : test dynamique (Windows : C:/workspaces réel jamais créé)"
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  H="$TMP/home"
  mkdir -p "$H"

  # Dépôt jetable : install.sh + fichiers existants (contenu non lu par install.sh) + .git vide
  REPO="$TMP/repo"
  mkdir -p "$REPO/git" "$REPO/ai" "$REPO/shell" "$REPO/wsl" "$TMP/bin"
  cp "$SRC" "$REPO/install.sh"
  : > "$REPO/git/gitconfig.work.example"; : > "$REPO/ai/rules.md"; printf 'test-wsl-config\n' > "$REPO/wsl/.wslconfig"
  for f in git_aliases.sh dev_aliases.sh jetbrains_path.sh bash_prompt.sh; do : > "$REPO/shell/$f"; done
  git init -q "$REPO"
  cat > "$TMP/bin/cmd.exe" <<EOF
#!/usr/bin/env bash
printf '%s\\r\\n' '$TMP/windows'
EOF
  cat > "$TMP/bin/wslpath" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1"
EOF
  chmod +x "$TMP/bin/cmd.exe" "$TMP/bin/wslpath"

  # Aucun WORKSPACE hérité : seul le défaut est testé
  unset WORKSPACE
  if ! env PATH="$TMP/bin:$PATH" HOME="$H" SHELL="${SHELL:-/bin/bash}" APPDATA=/nonexistent bash "$REPO/install.sh" > "$TMP/install.log" 2>&1; then
    cat "$TMP/install.log" >&2; fail "install.sh a échoué (HOME temporaire)"
  fi
  pass "install.sh exécuté dans HOME temporaire, sans WORKSPACE"

  [ -d "$H/workspaces/pro" ] && [ -d "$H/workspaces/perso" ] \
    && pass "workspaces/pro et workspaces/perso créés" \
    || fail "workspaces/pro ou workspaces/perso absent sous $H"
  [ ! -e "$H/workspace" ] && pass "aucun dossier workspace (singulier) créé" \
    || fail "dossier $H/workspace créé"

  # Export écrit dans le RC de l'OS (zsh ou bash selon l'OS / SHELL) : on accepte l'un ou l'autre
  exp="$(grep -hxF -- "export WORKSPACE=\"$H/workspaces\"" "$H/.zshrc" "$H/.bashrc" 2>/dev/null || true)"
  [ -n "$exp" ] && pass "export WORKSPACE=\"$H/workspaces\" écrit dans le RC" \
    || fail "export WORKSPACE par défaut absent du RC ($H/.zshrc ou $H/.bashrc)"

  gc="$(grep -hF -- "gitdir/i:$H/workspaces/pro/" "$H/.gitconfig" 2>/dev/null || true)"
  [ -n "$gc" ] && pass "includeIf gitdir pointe sur workspaces/pro" \
    || fail "includeIf gitdir absent ou ne pointe pas sur $H/workspaces/pro/"

  # Surcharge WORKSPACE=<HOME>/custom-workspaces : HOME temporaire distinct, sans dossier par défaut
  H2="$TMP/home-override"
  W="$H2/custom-workspaces"
  mkdir -p "$H2"
  if ! env PATH="$TMP/bin:$PATH" HOME="$H2" WORKSPACE="$W" SHELL="${SHELL:-/bin/bash}" APPDATA=/nonexistent bash "$REPO/install.sh" > "$TMP/install-override.log" 2>&1; then
    cat "$TMP/install-override.log" >&2; fail "install.sh a échoué (WORKSPACE surchargé, HOME temporaire)"
  fi
  pass "install.sh exécuté avec WORKSPACE=<HOME>/custom-workspaces"

  [ -d "$W/pro" ] && [ -d "$W/perso" ] \
    && pass "custom-workspaces/pro et custom-workspaces/perso créés" \
    || fail "custom-workspaces/pro ou custom-workspaces/perso absent sous $W"
  [ ! -e "$H2/workspaces" ] && pass "aucun dossier workspaces par défaut créé par la surcharge" \
    || fail "dossier $H2/workspaces créé par la surcharge"

  exp="$(grep -hxF -- "export WORKSPACE=\"$W\"" "$H2/.zshrc" "$H2/.bashrc" 2>/dev/null || true)"
  [ -n "$exp" ] && pass "export WORKSPACE=\"$W\" écrit dans le RC" \
    || fail "export WORKSPACE surchargé absent du RC ($H2/.zshrc ou $H2/.bashrc)"

  gc="$(grep -hF -- "gitdir/i:$W/pro/" "$H2/.gitconfig" 2>/dev/null || true)"
  [ -n "$gc" ] && pass "includeIf gitdir pointe sur custom-workspaces/pro" \
    || fail "includeIf gitdir absent ou ne pointe pas sur $W/pro/"

  rm -rf "$H2"; pass "scénario de surcharge nettoyé"
fi

echo OK
exit 0
