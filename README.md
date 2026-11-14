# dotfiles

Config git (et alias shell) pour **macOS (zsh)** et **Windows (Git Bash)**.

## Installation
    git clone <url> ~/workspace/dotfiles && cd ~/workspace/dotfiles && ./install.sh

Le script détecte l'OS, sauvegarde un éventuel `~/.gitconfig`, puis le remplace par
des `include` vers `git/gitconfig` (commun) et `git/gitconfig.<mac|windows>`.
Les réglages spécifiques à une machine vont dans `~/.gitconfig.local` (non versionné).

## Structure
- `git/gitconfig` — commun
- `git/gitconfig.mac` / `git/gitconfig.windows` — par OS
- `shell/git_aliases.sh` — alias, sourcé depuis `~/.zshrc` / `~/.bashrc`

## Paquets
`./install.sh --packages` : Homebrew (`packages/Brewfile`) ou MacPorts (`packages/macports.txt`) sur Mac, Scoop (`packages/scoop.txt`, sans admin) sur Windows.

## Workspace
- Mac : `~/workspace/{work,perso}` — Windows : `C:/workspace/{work,perso}` (surcharge : `WORKSPACE=D:/dev ./install.sh`).
- Les repos sous `work/` utilisent l'identité de `~/.gitconfig.work`, les autres l'identité perso.

## Secrets
Aucun identifiant dans ce repo. Identité pro, tokens et réglages machine vont dans `~/.gitconfig.work` / `~/.gitconfig.local` (hors repo, ignorés par `.gitignore`). Un hook `hooks/pre-commit` bloque les secrets probables ; credentials gérés par le trousseau (`osxkeychain` / Git Credential Manager).
