GETAROUND_ROOT="$HOME/getaround"

# aliases to protect against mistakes (force interactive mode)
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# basic command customization aliases
alias df='df -h'

# git aliases
alias gs='git status'
alias gca='git commit -a'
alias gp='git push'

# directory navigation aliases
alias ..='cd ..'
alias ...='cd ../..'

# misc aliases
alias ls="ls --color"
alias vim="vim -u $GETAROUND_ROOT/vimrc"
alias ta='tmux attach || tmux new'

# none, visible or audible
set bell-style none

# disable/enable 8bit input
#set meta-flag on
#set input-meta on
#set output-meta on
#set convert-meta off

# use vi key bindings for input
# https://blog.bugsnag.com/tmux-and-vim/
set editing-mode vi
set keymap vi

# Fix Ctrl-L not clearing screen in Bash
#set keymap vi-insert
#$if Bash
#"\C-l": "\e\C-la"
#$endif

# help
function getaround {
  echo "Welcome to getaround."
}

# git quicksave: commit and push
save() {
  if [ -z "${1+x}" ]; then
    echo "Missing commit message.";
  else
    git commit -a -m "$1" && git push
  fi
}

