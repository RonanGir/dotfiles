# Prompt Git Bash imitant le thème oh-my-zsh "robbyrussell" : ➜  dossier git:(branche) ✗
[ -n "${BASH_VERSION:-}" ] || return 0
if ! type __git_ps1 >/dev/null 2>&1; then
  for f in /mingw64/share/git/completion/git-prompt.sh /usr/share/git/completion/git-prompt.sh; do
    [ -f "$f" ] && . "$f" && break
  done
fi
GIT_PS1_SHOWDIRTYSTATE=1
__rr_git() {
  local b; b="$(__git_ps1 '%s' 2>/dev/null)" || return
  [ -n "$b" ] && printf ' \001\033[1;34m\002git:(\001\033[0;31m\002%s\001\033[1;34m\002)\001\033[0m\002' "${b%\*}$([[ $b == *\* ]] && printf ' ✗')"
}
PS1='\[\033[1;32m\]➜ \[\033[0;36m\] \W\[\033[0m\]$(__rr_git) '
