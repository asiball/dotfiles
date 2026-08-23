# dotfiles/setup.sh の補完
complete -c setup.sh -f
complete -c setup.sh -n __fish_use_subcommand -a 'install status diff dump help'
complete -c setup.sh -n '__fish_seen_subcommand_from install diff' -a 'all dotfiles packages'
