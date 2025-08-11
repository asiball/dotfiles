export LSCOLORS=Gxfxcxdxbxegedabagacad

# https://github.com/oh-my-fish/plugin-peco
function fish_user_key_bindings
  bind \cr 'peco_select_history (commandline -b)'
end



### ==== set theme LAVA =====
set fish_color_normal normal
set fish_color_command FF9400
set fish_color_redirection BF5B30
set fish_color_error FFDD73
set fish_color_quote BF9C30
set fish_color_end FF4C00
set fish_color_param FFC000
set fish_color_comment A63100
set fish_color_match --background=brblue
set fish_color_selection white --bold --background=brblack
set fish_color_search_match bryellow --background=brblack
set fish_color_history_current --bold
set fish_color_operator 00a6b2
set fish_color_escape 00a6b2
set fish_color_cwd green
set fish_color_cwd_root red
set fish_color_valid_path --underline
set fish_color_autosuggestion FFC473
set fish_color_user brgreen
set fish_color_host normal
set fish_pager_color_completion normal
set fish_color_cancel -r
set fish_pager_color_description B3A06D yellow
set fish_pager_color_prefix normal --bold --underline
set fish_pager_color_progress brwhite --background=cyan
### ====================



### >>>>>> prompt >>>>>>>>
# import : https://qiita.com/mom0tomo/items/b593c0e98c1eea70a114
# Fish git prompt
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_color_branch brcyan
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red

# Status Chars
set __fish_git_prompt_char_dirtystate '⚡'
set __fish_git_prompt_char_stagedstate '→'
set __fish_git_prompt_char_untrackedfiles '☡'
set __fish_git_prompt_char_stashstate '↩'
set __fish_git_prompt_char_upstream_ahead '+'
set __fish_git_prompt_char_upstream_behind '-'
### >>>>>> until here >>>>>>>>




### ====== alias ====== 
alias l='ls -l'
alias h='history'
alias python='python3'
alias pwdc='pwd| tr -d ''\n'' | pbcopy'
alias o='open'
alias tree='tree -NC'
alias cronlist='crontab -l'
alias croncron='crontab ~/.cron.conf; echo -- cron reload! -- ; cronlist'
alias vimcron='vim ~/.cron.conf; croncron'
### ====================



### ====== PATH =======
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
### ====================



### ======= iTerm =====
source ~/.iterm2_shell_integration.fish
### ====================



### ==== pyenv ====
#alias brew="env PATH=(string replace (pyenv root)/shims '' \"\$PATH\") brew"
#status is-login; and pyenv init --path | source
#status is-interactive; and pyenv init - | source
### ====================


### ====== Conda =====
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# eval $HOME/miniconda3/bin/conda "shell.fish" "hook" $argv | source
# <<< conda initialize <<<
# conda activate conda_jupyter
# alias act='conda activate'
# alias deact='conda deactivate'
### ====================

# Created by `pipx` on 2024-03-13 11:10:06
set PATH $PATH $HOME/.local/bin

# add ssh keys on 1password
set -x SSH_AUTH_SOCK ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
uv generate-shell-completion fish | source
