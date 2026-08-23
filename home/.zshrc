# vim:set foldmethod=marker:

##--------------
## HISTORY {{{
##--------------
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt share_history
setopt hist_ignore_dups
setopt auto_pushd
setopt pushd_ignore_dups
# }}}


##--------------
## 初期設定 {{{
##--------------

source ~/.bashrc
# }}}


##--------------
## visual
##--------------
autoload -Uz colors
colors
fpath+=~/.zfunc
autoload -Uz compinit
compinit
export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
zstyle ':completion:*' menu select


##--------------
## PROMPTの設定 {{{
##--------------
PROMPT="%B%F{green}%n@%m%f%b:%B%F{yellow}%~%b%f
%F{default}%# "
RPROMPT="%*"
### }}}


##--------------
## aliasの設定 {{{
##--------------

# general
alias reload='source ~/.zshrc'
alias h='history'
alias pip='pip3'
alias zshrc='vim ~/.zshrc'

alias ls='ls -Gp'
alias ll='ls -alGp'
alias la='ls -Ap'

alias cdd='cd $HOME'

alias tree='tree -NC'

alias du='du -sh *'
alias tm='terminal'
alias rm='rm -i'
alias pwdc="pwd | tr -d '\n' | clipcopy"

alias cronlist='crontab -l'
alias croncron='crontab ~/.cron.conf;echo -- cron reload! -- ; cronlist'
alias vimcron='vim ~/.cron.conf; croncron'

export LSCOLORS="Gxfxcxdxbxegedabagacad"

cdls(){
  \cd "$@" && ls
}
alias cd="cdls"
### }}}


## PATH(~/.local/bin は .bashrc で追加済み。マシン固有のものは ~/.bashrc.local へ)
export PATH="/usr/local/sbin:$PATH"
