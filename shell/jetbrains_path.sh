# Ajoute les lanceurs JetBrains Toolbox (idea, etc.) au PATH.
# Toolbox > Paramètres > Tools > "Generate shell scripts" doit être activé.
case "$(uname -s)" in
  Darwin) d="$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ;;
  MINGW*|MSYS*|CYGWIN*) d="$LOCALAPPDATA/JetBrains/Toolbox/scripts" ;;
esac
[ -d "${d:-}" ] && case ":$PATH:" in *":$d:"*) ;; *) export PATH="$PATH:$d" ;; esac
unset d
