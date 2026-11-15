#!/usr/bin/env bash
# Test d'idempotence de install.sh (sources du shell, dont les chemins Windows C:/ et /c/ à casse libre).
# Isolé : HOME, APPDATA et WORKSPACE temporaires ; install.sh tourne dans une copie avec un .git jetable
# (aucune modification du dépôt, du vrai home ou de VS Code). Sans --packages.
# Arrêt au premier écart (code 1) ; OK en dernière ligne seulement si tout passe.
# Usage : bash tests/install_idempotence.sh   (INSTALL_SRC=chemin permet de tester une autre version de install.sh)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${INSTALL_SRC:-$ROOT/install.sh}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
IS_WIN=0
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WIN=1 ;; esac

pass() { echo "ok   : $*"; }
fail() { echo "FAIL : $*" >&2; exit 1; }

# Chemin natif du dossier $1 (C:/... sous Windows, sinon chemin POSIX)
native() { if [ "$IS_WIN" = 1 ]; then (cd "$1" && pwd -W); else (cd "$1" && pwd); fi; }

# Dépôt jetable : install.sh + fichiers existants (contenu non lu par install.sh) + .git vide
# (install.sh ne pose core.hooksPath que si $DIR/.git existe ; seul .git/config du jetable est écrit)
REPO="$TMP/repo"
mkdir -p "$REPO/git" "$REPO/ai" "$REPO/shell"
cp "$SRC" "$REPO/install.sh"
: > "$REPO/git/gitconfig.work.example"; : > "$REPO/ai/rules.md"
for f in git_aliases.sh dev_aliases.sh jetbrains_path.sh bash_prompt.sh; do : > "$REPO/shell/$f"; done
git init -q "$REPO"
WS="$(native "$TMP")/ws"

# core.hooksPath doit valoir hooks dans le dépôt jetable après chaque installation
check_hooks() {
  [ "$(git -C "$REPO" config --get core.hooksPath || true)" = hooks ] \
    && pass "$1 : core.hooksPath=hooks" || fail "$1 : core.hooksPath absent ou différent"
}

# Lance install.sh avec HOME/APPDATA/WORKSPACE isolés : $1 = HOME, $2 = nom de la passe
run_install() {
  if ! HOME="$1" APPDATA=/nonexistent WORKSPACE="$WS" bash "$REPO/install.sh" > "$TMP/$2.log" 2>&1; then
    cat "$TMP/$2.log" >&2; fail "install.sh a échoué ($2)"
  fi
  check_hooks "$2"
}

# Nombre de lignes de $1 contenant $2 (casse ignorée)
count() { grep -ciF -- "$2" "$1" || true; }

# Nombre de lignes "# dotfiles" de $1 (0 si le fichier n'existe pas)
dotfiles_count() { if [ -f "$1" ]; then count "$1" "# dotfiles"; else echo 0; fi; }

# Exige exactement $2 lignes "# dotfiles" dans $1 ; arrêt immédiat sinon. $3 = libellé
check_dotfiles() {
  local n
  n="$(dotfiles_count "$1")"
  [ "$n" = "$2" ] && pass "$3 : $n ligne(s) \"# dotfiles\"" \
    || fail "$3 : $n ligne(s) \"# dotfiles\", attendu $2 ($1)"
}

# Chaque source doit apparaître exactement une fois
check_sources() {
  local s
  for s in shell/git_aliases.sh shell/dev_aliases.sh shell/jetbrains_path.sh; do
    [ "$(count "$1" "$s")" = 1 ] && pass "$2 : $s une seule fois" || fail "$2 : $s présent $(count "$1" "$s") fois"
  done
  if [ "$IS_WIN" = 1 ]; then
    [ "$(count "$1" shell/bash_prompt.sh)" = 1 ] && pass "$2 : bash_prompt.sh une seule fois" || fail "$2 : bash_prompt.sh présent $(count "$1" shell/bash_prompt.sh) fois"
  fi
}

# Ligne source au format écrit par add_source
source_line() { printf '\n# dotfiles\n[ -f "%s" ] && . "%s"\n' "$1" "$1"; }

# Passe 1 : première installation
# Blocs "# dotfiles" attendus après install : export WORKSPACE (1) + 3 sources + bash_prompt sous Windows
H1="$TMP/home1"; mkdir -p "$H1"
EXPECTED_FIRST=$((1 + 3 + IS_WIN))
check_dotfiles "$H1/.bashrc" 0 "1re installation, avant"
run_install "$H1" install1
check_sources "$H1/.bashrc" "1re installation"
check_dotfiles "$H1/.bashrc" "$EXPECTED_FIRST" "1re installation, après"

# Passe 2 : seconde installation, le .bashrc ne doit pas changer
cp "$H1/.bashrc" "$TMP/bashrc.before"
run_install "$H1" install2
if cmp -s "$TMP/bashrc.before" "$H1/.bashrc"; then pass "2e installation : .bashrc inchangé"
else fail "2e installation : .bashrc modifié"; diff "$TMP/bashrc.before" "$H1/.bashrc" >&2 || true; fi
check_sources "$H1/.bashrc" "2e installation"
check_dotfiles "$H1/.bashrc" "$EXPECTED_FIRST" "2e installation, après"

# Scénario Windows : $1 = libellé, $2 = préfixe du repo tel qu'écrit dans .bashrc, $3 = nom du HOME temporaire.
# WORKSPACE est préremplie dans la fixture : install.sh n'ajoute pas son bloc "export WORKSPACE".
# Vérifie qu'aucun doublon n'est ajouté (1re passe puis relance, .bashrc inchangé à la relance).
win_scenario() {
  local label="$1" base="$2" home="$TMP/$3" f
  local EXPECTED=4   # 4 blocs source_line écrits par la fixture, aucun bloc ajouté par install.sh
  mkdir -p "$home"
  {
    printf 'export WORKSPACE="%s"\n' "$WS"
    for f in shell/git_aliases.sh shell/dev_aliases.sh shell/jetbrains_path.sh shell/bash_prompt.sh; do
      source_line "$base/$f"
    done
  } > "$home/.bashrc"
  check_dotfiles "$home/.bashrc" "$EXPECTED" "$label, avant"
  run_install "$home" "$3-1"
  check_sources "$home/.bashrc" "$label, 1re passe"
  check_dotfiles "$home/.bashrc" "$EXPECTED" "$label, 1re passe, après"
  cp "$home/.bashrc" "$TMP/$3.before"
  run_install "$home" "$3-2"
  if cmp -s "$TMP/$3.before" "$home/.bashrc"; then pass "$label : relance, .bashrc inchangé"
  else fail "$label : relance, .bashrc modifié"; fi
  check_sources "$home/.bashrc" "$label, relance"
  check_dotfiles "$home/.bashrc" "$EXPECTED" "$label, relance, après"
}

# Passe 3 (Windows) : sources déjà présentes sous deux formes du même chemin
if [ "$IS_WIN" = 1 ]; then
  WIN_REPO="$(native "$REPO")"                        # C:/Users/.../repo
  drive="$(echo "${WIN_REPO%%:*}" | tr A-Z a-z)"
  # 3a : forme /c/... entièrement en minuscules
  VAR_LC="$(echo "/${drive}${WIN_REPO#*:}" | tr A-Z a-z)"
  # 3b : forme C:/... entièrement en majuscules si WIN_REPO ne l'est pas, sinon entièrement en minuscules
  if [ "$WIN_REPO" = "$(echo "$WIN_REPO" | tr a-z A-Z)" ]; then VAR_UC="$(echo "$WIN_REPO" | tr A-Z a-z)"
  else VAR_UC="$(echo "$WIN_REPO" | tr a-z A-Z)"; fi
  [ "$VAR_UC" != "$WIN_REPO" ] || fail "fixture 3b : forme injectée identique à pwd -W ($WIN_REPO)"
  win_scenario "forme /c/ minuscules (3a)" "$VAR_LC" home3a
  win_scenario "forme C:/ casse différente (3b)" "$VAR_UC" home3b
else
  echo "skip : formes /c/ et C:/ à casse différente (hors Windows)"
fi

echo OK
exit 0
