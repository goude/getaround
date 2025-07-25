# Environment
export GETAROUND_ROOT="$HOME/getaround"
export EDITOR=nvim

###--- PROTECTIVE ALIASES ---###
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

###--- BASIC COMMAND ALIASES ---###
alias df='df -h'
alias ls='ls --color'
alias ..='cd ..'
alias ...='cd ../..'
alias ta='tmux attach || tmux new'
alias n='nvim'

###--- GIT ALIASES ---###
alias gs='git status'
alias ga='git add'
alias gca='git commit -a'
alias gp='git push'

###--- SYSTEM SHORTCUTS ---###
alias sau='sudo apt update && sudo apt upgrade -y'

###--- SHELL BEHAVIOR ---###
set -o vi           # vi keybindings
set bell-style none # no bell sound

# Show vi mode in prompt
bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string "\1\e[32m\2[INS]\1\e[0m\2 "'
bind 'set vi-cmd-mode-string "\1\e[31m\2[NORMAL]\1\e[0m\2 "'

# Optional Ctrl-F menu completion (Fish-like)
bind '"\C-f": menu-complete'

# Clear screen in vi-insert mode with Ctrl-L
bind -m vi-insert '"\C-l": clear-screen'

# Disable terminal software flow control (XON/XOFF) with stty -ixon
# ---------------------------------------------------------------
# By default, Ctrl+S and Ctrl+Q are used by the terminal to pause/resume output:
#   - Ctrl+S sends XOFF (pause transmission)
#   - Ctrl+Q sends XON (resume transmission)
#
# This behavior is a relic of older serial terminal communication,
# but still enabled by many terminal emulators today.
#
# The problem: Ctrl+S doesn't reach applications like Vim/Neovim because
# the terminal intercepts it first and pauses output instead.
#
# Solution: 'stty -ixon' disables this flow control feature at the terminal level,
# allowing Ctrl+S to be passed through to applications like Neovim,
# where you can then map it to :w (save), etc.
#
# Safe to use in modern setups — keyboard flow control is rarely needed anymore.
stty -ixon

###--- ENHANCED HISTORY / SUGGESTIONS ---###

# Fzf fuzzy search (Ctrl-R enhanced history)
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

###--- FUNCTIONS ---###

# Welcome/help function
function getaround {
  echo "Welcome to getaround."
}

# Git quicksave: commit and push
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
  [[ -f ~/.gitignore ]] || touch ~/.gitignore

  git config --list
}
