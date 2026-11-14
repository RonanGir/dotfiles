# Alias de nettoyage dev (zsh + Git Bash). Opèrent sur "${WORKSPACE:-$HOME/workspace}".
alias clean-java='find "${WORKSPACE:-$HOME/workspace}" -type d \( -name "target" -o -name "build" \) -prune -exec rm -rf {} + && echo "Caches Java purgés."'
alias clean-node='npx npkill -d "${WORKSPACE:-$HOME/workspace}"'

devclean() {
  find "${WORKSPACE:-$HOME/workspace}" -name node_modules -type d -prune -exec rm -rf '{}' + && echo "node_modules supprimés."
  find "${WORKSPACE:-$HOME/workspace}" -name target       -type d -prune -exec rm -rf '{}' + && echo "target (Maven) supprimés."
  find "${WORKSPACE:-$HOME/workspace}" -name build        -type d -prune -exec rm -rf '{}' + && echo "build (Gradle) supprimés."
}
