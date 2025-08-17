# env
export GETAROUND_ROOT="$HOME/repos/getaround"
export EDITOR=nvim

# protective aliases
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# basic aliases
if ls --color >/dev/null 2>&1; then
  alias ls='ls --color'
else
  alias ls='ls -G' 2>/dev/null || alias ls='ls'
fi
alias df='df -h'
alias ..='cd ..'
alias ...='cd ../..'
alias ta='tmux attach || tmux new'
alias n='nvim'

# git aliases
alias gs='git status'
alias ga='git add'
alias gca='git commit -a'
alias gp='git push'

# system shortcuts
alias sau='sudo apt update && sudo apt upgrade -y'

# terminal flow control
stty -ixon 2>/dev/null || true

# helpers
_warn() { printf '%s\n' "$*" >&2; }

# pbcopy/pbpaste cross-platform
if ! command -v pbcopy >/dev/null 2>&1; then
  case "$OSTYPE" in
    darwin*)
      # native on macOS; nothing to do
      :
      ;;
    linux*)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        # WSL
        pbcopy() { clip.exe; }
        pbpaste() { powershell.exe -NoLogo -NoProfile -Command Get-Clipboard; }
      elif command -v xclip >/dev/null 2>&1; then
        pbcopy()  { xclip -selection clipboard; }
        pbpaste() { xclip -selection clipboard -o; }
      elif command -v xsel >/dev/null 2>&1; then
        pbcopy()  { xsel --clipboard --input; }
        pbpaste() { xsel --clipboard --output; }
      else
        pbcopy()  { _warn "pbcopy unavailable: install xclip or xsel (Linux)"; return 127; }
        pbpaste() { _warn "pbpaste unavailable: install xclip or xsel (Linux)"; return 127; }
      fi
      ;;
    *)
      pbcopy()  { _warn "pbcopy unsupported on this platform"; return 127; }
      pbpaste() { _warn "pbpaste unsupported on this platform"; return 127; }
      ;;
  esac
fi

# functions
getaround() {
  echo "Welcome to getaround."
}

save() {
  if [ -z "$1" ]; then
    echo "Missing commit message."
  else
    git commit -a -m "$1" && git push
  fi
}

rcg() {
  echo "Setting up default global git configuration for Daniel Goude."

  git config --global user.name 'Daniel Goude'
  git config --global user.email 'daniel@goude.se'
  git config --global push.default simple
  git config --global pull.rebase false
  git config --global core.editor vim
  git config --global init.defaultBranch main

  git config --global diff.tool vimdiff
  git config --global merge.tool vimdiff

  git config --global core.excludesfile ~/.gitignore
  [ -f ~/.gitignore ] || touch ~/.gitignore

  git config --list
}

# bash-specific
if [ -n "$BASH_VERSION" ]; then
  set -o vi
  set bell-style none
  bind 'set show-mode-in-prompt on'
  bind 'set vi-ins-mode-string "\1\e[32m\2[INS]\1\e[0m\2 "'
  bind 'set vi-cmd-mode-string "\1\e[31m\2[NORMAL]\1\e[0m\2 "'
  bind '"\C-f": menu-complete'
  bind -m vi-insert '"\C-l": clear-screen'
  [ -f ~/.fzf.bash ] && source ~/.fzf.bash
fi

# zsh-specific
if [ -n "$ZSH_VERSION" ]; then
  bindkey -v
  setopt NO_BEEP
  setopt PROMPT_SUBST

  zle-keymap-select() {
    case $KEYMAP in
      vicmd) RPROMPT='%F{red}[NORMAL]%f ' ;;
      main|viins) RPROMPT='%F{green}[INS]%f ' ;;
      *) RPROMPT='' ;;
    esac
    zle reset-prompt
  }
  zle -N zle-keymap-select

  zle-line-init() { zle-keymap-select; }
  zle -N zle-line-init

  bindkey -M viins '^F' menu-complete
  bindkey -M vicmd '^F' menu-complete
  bindkey -M viins '^L' clear-screen

  autoload -Uz complist 2>/dev/null || true
  zmodload zsh/complist 2>/dev/null || true
  zstyle ':completion:*' menu select

  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# install helper
install-getaround() {
  # choose target rc file
  local target_rc
  if [ -n "$1" ]; then
    target_rc="$1"
  elif [ -n "$ZSH_VERSION" ]; then
    target_rc="$HOME/.zshrc"
  else
    target_rc="$HOME/.bashrc"
  fi

  # resolve absolute path to this script (bash, zsh, or sh)
  local src_path dir base
  if [ -n "$BASH_SOURCE" ]; then
    src_path="${BASH_SOURCE[0]}"
  elif [ -n "$ZSH_VERSION" ]; then
    # zsh: current script path
    src_path="${(%):-%x}"
  else
    src_path="$0"
  fi

  # try realpath, else portable resolution
  if command -v realpath >/dev/null 2>&1; then
    src_path="$(realpath "$src_path")"
  else
    dir="$(cd "$(dirname "$src_path")" >/dev/null 2>&1 && pwd -P)"
    base="$(basename "$src_path")"
    src_path="$dir/$base"
  fi

  [ -f "$target_rc" ] || touch "$target_rc"

  # idempotent insertion
  if grep -Fq '>>> getaround init >>>' "$target_rc"; then
    echo "Already installed in $target_rc"
  else
    {
      echo ''
      echo '# >>> getaround init >>>'
      echo "source \"$src_path\""
      echo '# <<< getaround init <<<'
    } >> "$target_rc"
    echo "Installed: added source line to $target_rc"
  fi

  # shell hint
  echo "Open a new shell or run: source \"$target_rc\""
}

