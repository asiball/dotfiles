# ~/.bashrc(macOS / Linux 共通。マシン固有の設定は ~/.bashrc.local へ)
# .zshrc からも source されるため、bash 専用の機能は $BASH_VERSION でガードする

case $- in *i*) ;; *) return ;; esac   # 対話シェル以外では何もしない

# 履歴
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
if [ -n "$BASH_VERSION" ]; then
    shopt -s histappend checkwinsize
fi

# プロンプト(root は赤、一般ユーザーは緑)
if [ "$UID" -eq 0 ]; then
    PS1="\n\[\033[31m\]\u@\h\[\033[97m\]:\[\033[01;93m\]\w\[\033[97m\] \\$\[\033[00m\] "
else
    PS1="\n\[\033[32;01m\]\u@\h\[\033[97m\]:\[\033[01;93m\]\w\[\033[97m\] \\$\[\033[00m\] "
fi

# 色付き ls / grep
if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
else
    export CLICOLOR=1   # macOS / BSD ls
fi

# 補完
if [ -n "$BASH_VERSION" ] && ! shopt -oq posix; then
    for f in /usr/share/bash-completion/bash_completion /etc/bash_completion /opt/homebrew/etc/profile.d/bash_completion.sh; do
        if [ -f "$f" ]; then . "$f"; break; fi
    done
fi

export PATH="$HOME/.local/bin:$PATH"

[ -f ~/.bash_aliases ] && . ~/.bash_aliases
[ -f ~/.bashrc.local ] && . ~/.bashrc.local
