# Alias de nettoyage dev (zsh + Git Bash). Opèrent sur "${WORKSPACE:-$HOME/workspaces}".
alias clean-java='find "${WORKSPACE:-$HOME/workspaces}" -type d \( -name "target" -o -name "build" \) -prune -exec rm -rf {} + && echo "Caches Java purgés."'
alias clean-node='npx npkill -d "${WORKSPACE:-$HOME/workspaces}"'

devclean() {
  find "${WORKSPACE:-$HOME/workspaces}" -name node_modules -type d -prune -exec rm -rf '{}' + && echo "node_modules supprimés."
  find "${WORKSPACE:-$HOME/workspaces}" -name target       -type d -prune -exec rm -rf '{}' + && echo "target (Maven) supprimés."
  find "${WORKSPACE:-$HOME/workspaces}" -name build        -type d -prune -exec rm -rf '{}' + && echo "build (Gradle) supprimés."
}
