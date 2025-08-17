# getaround.sh

# helpers
_ga_warn() { printf '%s\n' "$*" >&2; }

# resolve absolute path of this script
_ga_script_path() {
  local src dir base
  if [ -n "$BASH_SOURCE" ]; then
    src="${BASH_SOURCE[0]}"
  elif [ -n "$ZSH_VERSION" ]; then
    src="${(%):-%x}"
  else
    src="$0"
  fi

  if command -v realpath >/dev/null 2>&1; then
    realpath "$src"
  else
    dir="$(cd "$(dirname "$src")" >/dev/null 2>&1 && pwd -P)"
    base="$(basename "$src")"
    printf '%s/%s\n' "$dir" "$base"
  fi
}

# env
GETAROUND_VERSION="1.0.2"

# set EDITOR dynamically: nvim > vim > vi > nano (fallback vi)
for candidate in nvim vim vi nano; do
  if command -v "$candidate" >/dev/null 2>&1; then
    export EDITOR="$candidate"
    break
  fi
done
: "${EDITOR:=vi}"

# set GETAROUND_ROOT dynamically (to script's directory)
if [ -z "$GETAROUND_ROOT" ]; then
  script_path="$(_ga_script_path)"
  export GETAROUND_ROOT="$(cd "$(dirname "$script_path")" && pwd -P)"
fi

# optional bin on PATH
if [ -d "$GETAROUND_ROOT/bin" ]; then
  case ":$PATH:" in
    *":$GETAROUND_ROOT/bin:"*) : ;;
    *) PATH="$GETAROUND_ROOT/bin:$PATH" ;;
  esac
fi

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

# pbcopy/pbpaste cross-platform
if ! command -v pbcopy >/dev/null 2>&1; then
  case "$OSTYPE" in
    darwin*) : ;; # native on macOS
    linux*)
      # detect WSL
      if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null || \
         grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease 2>/dev/null; then
        pbcopy()  { clip.exe; }
        pbpaste() { powershell.exe -NoLogo -NoProfile -Command Get-Clipboard | tr -d '\r'; }
      elif command -v xclip >/dev/null 2>&1; then
        pbcopy()  { xclip -selection clipboard; }
        pbpaste() { xclip -selection clipboard -o; }
      elif command -v xsel >/dev/null 2>&1; then
        pbcopy()  { xsel --clipboard --input; }
        pbpaste() { xsel --clipboard --output; }
      else
        pbcopy()  { _ga_warn "pbcopy unavailable: install xclip or xsel (Linux)"; return 127; }
        pbpaste() { _ga_warn "pbpaste unavailable: install xclip or xsel (Linux)"; return 127; }
      fi
      ;;
    *)
      pbcopy()  { _ga_warn "pbcopy unsupported on this platform"; return 127; }
      pbpaste() { _ga_warn "pbpaste unsupported on this platform"; return 127; }
      ;;
  esac
fi

# functions
ga-welcome() { printf 'Welcome to getaround (%s). EDITOR=%s\n' "$GETAROUND_VERSION" "$EDITOR"; }
getaround()  { ga-welcome; }

ga-save() {
  if [ -z "$1" ]; then
    echo "Missing commit message."
  else
    git commit -a -m "$1" && git push
  fi
}

ga-rcg() {
  if ! command -v git >/dev/null 2>&1; then
    _ga_warn "git not found; cannot configure."
    return 127
  fi
  echo "Setting up default global git configuration for Daniel Goude."

  git config --global user.name 'Daniel Goude'
  git config --global user.email 'daniel@goude.se'
  git config --global push.default simple
  git config --global pull.rebase false
  git config --global core.editor "${EDITOR:-vi}"
  git config --global init.defaultBranch main

  git config --global diff.tool vimdiff
  git config --global merge.tool vimdiff

  git config --global core.excludesfile ~/.gitignore
  [ -f ~/.gitignore ] || touch ~/.gitignore

  git config --list
}

# fzf init portability
_ga_init_fzf() {
  if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.fzf.bash" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.fzf.bash"
  elif [ -n "$ZSH_VERSION" ] && [ -f "$HOME/.fzf.zsh" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.fzf.zsh"
  elif [ -n "$ZSH_VERSION" ] && command -v fzf-share >/dev/null 2>&1; then
    # shellcheck disable=SC1090
    source "$(fzf-share)/key-bindings.zsh"
    # shellcheck disable=SC1090
    source "$(fzf-share)/completion.zsh"
  elif [ -d /usr/share/doc/fzf/examples ]; then
    if [ -n "$BASH_VERSION" ] && [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
      # shellcheck disable=SC1091
      source /usr/share/doc/fzf/examples/key-bindings.bash
      # shellcheck disable=SC1091
      source /usr/share/doc/fzf/examples/completion.bash
    elif [ -n "$ZSH_VERSION" ] && [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
      # shellcheck disable=SC1091
      source /usr/share/doc/fzf/examples/key-bindings.zsh
      # shellcheck disable=SC1091
      source /usr/share/doc/fzf/examples/completion.zsh
    fi
  fi
}

# help
ga-help() {
  cat <<'EOF'
getaround.sh installed.

Aliases:
  rm/mv/cp (interactive), ls (color), df, .., ..., ta, n
  gs, ga, gca, gp, sau
Functions:
  getaround           - prints welcome with version and current $EDITOR
  ga-save "msg"       - git commit -a -m "msg" && git push
  ga-rcg              - set Git globals (core.editor mirrors $EDITOR)
  install-getaround   - add/update source block in ~/.zshrc or ~/.bashrc
Clipboard:
  pbcopy/pbpaste      - macOS native; Linux via xclip/xsel; WSL via Windows clipboard
Notes:
  GETAROUND_ROOT set dynamically to this script’s directory.
  GETAROUND_ROOT/bin is prepended to PATH if it exists.
  EDITOR preference: nvim > vim > vi > nano.
EOF
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
  _ga_init_fzf
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

  _ga_init_fzf
fi

# fallback for other shells
if [ -z "$BASH_VERSION$ZSH_VERSION" ]; then
  _ga_warn "getaround.sh: non-bash/zsh shell detected; skipped shell-specific keybindings."
fi

# auto-run welcome when sourced (interactive only)
case $- in
  *i*) getaround ;;
esac

# ------------------------------------------------------------------------------
# install helper (idempotent rewrite of block) — kept last
install-getaround() {
  local target_rc block_start block_end src_path tmp
  block_start="# >>> getaround init >>>"
  block_end="# <<< getaround init <<<"

  if [ -n "$1" ]; then
    target_rc="$1"
  elif [ -n "$ZSH_VERSION" ]; then
    target_rc="$HOME/.zshrc"
  else
    target_rc="$HOME/.bashrc"
  fi

  src_path="$(_ga_script_path)"
  [ -f "$target_rc" ] || touch "$target_rc"
  tmp="$(mktemp "${TMPDIR:-/tmp}/getaround.XXXXXX")" || { _ga_warn "mktemp failed"; return 1; }

  if grep -Fq "$block_start" "$target_rc"; then
    awk -v start="$block_start" -v end="$block_end" -v path="$src_path" '
      BEGIN { inblk=0 }
      $0 ~ start { print start; print "source \"" path "\""; print end; inblk=1; next }
      $0 ~ end && inblk==1 { inblk=0; next }
      inblk==0 { print }
    ' "$target_rc" > "$tmp"
    mv "$tmp" "$target_rc"
    echo "Updated: source block in $target_rc"
  else
    {
      echo ""
      echo "$block_start"
      echo "source \"$src_path\""
      echo "$block_end"
    } >> "$target_rc"
    echo "Installed: added source block to $target_rc"
  fi

  echo "Reload with: source \"$target_rc\""
}
