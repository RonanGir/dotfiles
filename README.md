# dotfiles

Config git (et alias shell) pour **macOS (zsh)**, **Windows (Git Bash)** et **Linux / WSL**.

## Installation
    git clone <url> ~/workspaces/dotfiles && cd ~/workspaces/dotfiles && ./install.sh

Le script détecte l'OS, sauvegarde un éventuel `~/.gitconfig`, puis le remplace par
des `include` vers `git/gitconfig` (commun) et `git/gitconfig.<mac|windows|linux>` (+ `git/gitconfig.wsl` sous WSL).
Les réglages spécifiques à une machine vont dans `~/.gitconfig.local` (non versionné).

## Structure
- `git/gitconfig` — commun
- `git/gitconfig.mac` / `git/gitconfig.windows` / `git/gitconfig.linux` — par OS ; `git/gitconfig.wsl` — en plus sous WSL
- `shell/git_aliases.sh` — alias, sourcé depuis `~/.zshrc` / `~/.bashrc`

## Paquets
`./install.sh --packages` : Homebrew (`packages/Brewfile`) ou MacPorts (`packages/macports.txt`) sur Mac, Scoop (`packages/scoop.txt`, sans admin) sur Windows, apt (`packages/apt.txt`) sur Linux/WSL.

## Workspace
- Mac, Linux/WSL : `~/workspaces/{pro,perso}` — Windows : `C:/workspaces/{pro,perso}`.
- Surcharge : `WORKSPACE=D:/dev ./install.sh` (ou `WORKSPACE=~/custom-workspaces ./install.sh` pour un autre dossier personnalisé).
- Migration depuis `~/workspace` / `C:/workspace` : install.sh ne déplace ni ne supprime rien. Un `export WORKSPACE=` déjà présent dans `~/.zshrc` / `~/.bashrc` est conservé tel quel ; sinon, install.sh ajoute `export WORKSPACE="<home>/workspaces"` (chemin absolu). Pour garder un dépôt existant, déplacez-le vous-même vers `~/workspaces` (ou gardez `WORKSPACE` pointé sur l'ancien dossier). ⚠️ Relancer `install.sh` régénère `~/.gitconfig` et son `includeIf` d'identité (`gitdir/i:<WORKSPACE>/pro/`) à partir de la valeur courante de `WORKSPACE` : si elle a changé, les dépôts restés sous l'ancien dossier perdent l'identité pro. Déplacez d'abord les dépôts, puis relancez `install.sh`.
- Renommage : l'ancien sous-dossier `work/` devient `pro/` (install.sh ne le renomme pas). Renommez-le vous-même avant de relancer `install.sh`, sinon les repos pro perdent l'identité pro.
- WSL : `~/workspaces/{pro,perso}` dans le système de fichiers Linux (pas `/mnt/c`, trop lent). C'est un clone distinct de celui de Windows : clé SSH, `~/.gitconfig.work` et identité pro sont à configurer dans chaque WSL. VS Code reste géré côté Windows (extension Remote - WSL).
- WSL : `wsl/.wslconfig` est copié dans le profil Windows (`%USERPROFILE%\.wslconfig`) par `install.sh`, depuis Windows ou depuis WSL. Il active le réseau Mirrored, le DNS tunneling et le pare-feu Windows, désactive le swap et conserve une durée d'inactivité de quatre heures. Une copie `.bak.<date>` est créée si le fichier Windows existant diffère.
- Les repos sous `pro/` utilisent l'identité de `~/.gitconfig.work`, les autres l'identité perso.

## Secrets
Aucun identifiant dans ce repo. Identité pro, tokens et réglages machine vont dans `~/.gitconfig.work` / `~/.gitconfig.local` (hors repo, ignorés par `.gitignore`). Un hook `hooks/pre-commit` bloque les secrets probables ; credentials gérés par le trousseau (`osxkeychain` / Git Credential Manager).
