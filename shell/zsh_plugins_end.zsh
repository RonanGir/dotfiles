# À sourcer en DERNIER dans ~/.zshrc : coloration syntaxique (MacPorts ou Homebrew).
for f in /opt/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
         "$(command -v brew >/dev/null && brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
  [ -f "$f" ] && source "$f" && break
done
