# vim:set foldmethod=marker:
## zi : 折りたたみの有効無効の切り替え
## za : 折りたたみの開閉
## zf : 折りたたみの作成(範囲選択の開始行と終了行の末尾にマーカーを追加する){{{
## zA : 折りたたみの再帰的開閉
## zd : 折りたたみの削除
## zR : バッファ内の全ての折りたたみを開く
## zM : バッファ内の全ての折りたたみを閉じる}}}

##--------------
## HISTORY {{{
##--------------
HISTFILE=~/.zsh_history
HISTSIZE=1000 #保存するサイズ
SAVEhist=2000
setopt share_history #他のターミナルとヒストリーを共有
setopt hist_ignore_dups #直前に実行したコマンドは履歴に残さない
setopt share_history  #別タブで開いて実行したコマンドも入力履歴として共有する
setopt auto_pushd #cd+tabで以前移動したディレクトリを表示させる
setopt pushd_ignore_dups #同じディレクトリは追加させない
# }}}


##--------------
## 初期設定　 {{{
##--------------

source ~/.bashrc
# vimキーバインド
#bindkey -v
# Ctrl+Dでログアウトしてしまうことを防ぐ
#setopt IGNOREEOF

##--------------
## visual
##--------------
# 色の読み込み
#eval `dircolors /etc/DIR_COLORS`
autoload -Uz colors
colors
# 補完機能の追加
autoload -Uz compinit
compinit
# 補完時の色設定
export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
zstyle ':completion:*' menu select
##~~~~~~~~~~
### }}}


##--------------
## PROMPTの設定 {{{
##--------------
PROMPT="%B%F{green}%n@%m%f%b:%B%F{yellow}%~%b%f
%F{default}%# "
RPROMPT="%*"
###~~~~~~~~~~
### }}}


##--------------
## aliasの設定 {{{
##--------------

# general
alias reload='source ~/.zshrc'
alias h='history'
alias pip='pip3'
alias zshrc='vim ~/.zshrc'

# ~/.zprezto/modules/utility で上書きされてるっぽい
# ls
alias ls='ls -Gp'
alias ll='ls -alGp'
alias la='ls -Ap'

# cd
alias cdd='cd $HOME'

# tree
alias tree='tree -NC'

alias du='du -sh *'
alias tm='terminal'
alias rm='rm -i'
alias pwdc="pwd| tr -d '\n' | pbcopy"

alias cronlist='crontab -l'
alias croncron='crontab ~/.cron.conf;echo -- cron reload! -- ; cronlist'
alias vimcron='vim ~/.cron.conf; croncron'

#### ls -G の色の変更 ####
export LSCOLORS="Gxfxcxdxbxegedabagacad"

# cdls
cdls(){
  \cd "$@" && ls
}
alias cd="cdls"

###~~~~~~~~~~
### }}}


## PATH

# zprezto
#source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
#[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
#prompt powerlevel10k

export PATH="$PATH:$HOME/Local/mycommand"
export PATH="/usr/local/sbin:$PATH"


# poetry
fpath+=~/.zfunc
autoload -Uz compinit && compinit

# Created by `pipx` on 2024-03-31 03:19:45
export PATH="$PATH:$HOME/.local/bin"

