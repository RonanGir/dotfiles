# À sourcer en DERNIER dans ~/.zshrc : coloration syntaxique + autosuggestions (MacPorts ou Homebrew).
_prefixes=(/opt/local/share)
command -v brew >/dev/null && _prefixes+=("$(brew --prefix)/share")
for p in zsh-syntax-highlighting zsh-autosuggestions; do
  for d in "${_prefixes[@]}"; do
    [ -f "$d/$p/$p.zsh" ] && source "$d/$p/$p.zsh" && break
  done
done
unset _prefixes p d
