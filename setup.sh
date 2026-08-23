#!/bin/bash
# dotfiles セットアップ HUB。ロジックは stow / brew bundle / apt に委譲する。
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
OS="$(uname -s)"   # Darwin | Linux

usage() {
    cat <<USAGE
使い方: $0 <command> [target]

  install [all|dotfiles|packages]  リポジトリから展開する(既定: all)
  status                           dotfiles の同期状態を表示する
  diff    [all|dotfiles|packages]  実環境との差分を表示する(stow は dry-run)
  dump                             実環境の brew パッケージを Brewfile に書き出す(macOS)

環境変数:
  MAS=1   Mac App Store アプリ(Brewfile.mas)も対象に含める(要サインイン)

packages は macOS では brew bundle、Linux(Ubuntu/WSL2)では apt-packages.txt を使う。
USAGE
}

# 実行前に、導入されるもの・変更されるものを列挙して確認を取る
confirm_install() {
    echo "これから行うこと($1):"
    if [[ "$1" != dotfiles ]]; then
        case "$OS" in
            Darwin) echo "  - Homebrew(無ければ導入)+ brew bundle: Brewfile$(mas_enabled && echo ', Brewfile.mas')" ;;
            Linux)  echo "  - apt で導入: $(apt_packages)" ;;
        esac
    fi
    if [[ "$1" != packages ]]; then
        echo "  - stow(無ければ導入)で home/ を \$HOME に展開。衝突する既存ファイル・symlink は *.backup.<時刻> に退避"
        echo "  - ~/.gitconfig.local が無ければ作成、Claude Code の共有設定(hooks, statusLine)を ~/.claude/settings.json に合成(jq)"
        echo "  - fish があれば fisher とプラグインを導入$([[ "$OS" == Darwin ]] && echo '、既定シェルを fish に変更')"
    fi
    read -rp "続行しますか? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "中止しました"; exit 1; }
}

# ---------- packages ----------
ensure_homebrew() {
    command -v brew >/dev/null && return 0
    echo "Homebrew を導入します..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
    if [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi
}

mas_enabled() { [[ "${MAS:-}" == 1 ]] && command -v mas >/dev/null; }

apt_packages() { grep -v '^#' apt-packages.txt | xargs; }
apt_install()  { sudo apt-get update && sudo apt-get install -y "$@"; }

install_packages() {
    case "$OS" in
        Darwin)
            ensure_homebrew
            brew bundle install --no-upgrade --file=Brewfile
            if mas_enabled; then
                brew bundle install --no-upgrade --file=Brewfile.mas
            else
                echo "Mac App Store アプリはスキップしました(含めるには MAS=1)"
            fi
            ;;
        Linux)
            # shellcheck disable=SC2046
            apt_install $(apt_packages)
            ;;
    esac
}

dump_packages() {
    [[ "$OS" == Darwin ]] || { echo "dump は macOS 専用です"; exit 1; }
    ensure_homebrew
    brew bundle dump --force --no-vscode --no-mas --file=Brewfile
    if mas_enabled; then
        brew bundle dump --force --no-vscode --mas --no-formulae --no-casks --no-taps --file=Brewfile.mas
    fi
    echo "Brewfile を更新しました"
}

diff_packages() {
    case "$OS" in
        Darwin)
            echo "## Brewfile と実環境の差分"
            brew bundle check --verbose --file=Brewfile || true
            echo "## インストール済みだが Brewfile に無いもの"
            brew bundle cleanup --file=Brewfile || true
            if mas_enabled; then brew bundle check --verbose --file=Brewfile.mas || true; fi
            ;;
        Linux)
            echo "## apt-packages.txt のうち未インストール"
            # shellcheck disable=SC2046
            apt-get -s install $(apt_packages) 2>/dev/null | grep '^Inst' || echo "(なし)"
            ;;
    esac
}

# ---------- dotfiles ----------
ensure_stow() {
    command -v stow >/dev/null && return 0
    echo "GNU stow を導入します..."
    case "$OS" in
        Darwin) ensure_homebrew; brew install stow ;;
        Linux)  apt_install stow ;;
    esac
}

install_dotfiles() {
    ensure_stow
    # 衝突する既存ファイル(repo 以外を指す symlink、切れた symlink を含む)は退避してから展開する
    local ts rel target
    ts="$(date +%Y%m%d_%H%M%S)"
    while IFS= read -r rel; do
        target="$HOME/$rel"
        if [[ ( -e "$target" || -L "$target" ) && ! "$target" -ef "home/$rel" ]]; then
            mv "$target" "$target.backup.$ts"
            echo "退避: $rel -> $rel.backup.$ts"
        fi
    done < <(cd home && find . -type f | sed 's|^\./||')
    # --no-folding: ディレクトリは実体で作り、ファイルだけ symlink にする
    # (~/.config/fish が repo への symlink に畳まれると fisher 等が repo 内に書き込むため)
    stow --no-folding --restow --target="$HOME" home
    echo "dotfiles を $HOME に展開しました"

    # ~/.tmux.conf が残っていると ~/.config/tmux/tmux.conf が読まれない
    if [[ -e "$HOME/.tmux.conf" ]]; then
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$ts"
        echo "退避: .tmux.conf(~/.config/tmux/tmux.conf を使います)"
    fi

    ensure_gitconfig_local
    ensure_claude_settings
    ensure_fish_plugins
    ensure_fish_default_shell
}

# home/.claude/settings.shared.json(hooks, statusLine など)を ~/.claude/settings.json に合成する。
# settings.json 自体は環境依存値や機密を含むため repo 管理外。shared 側の項目で上書きし、それ以外は保持する
ensure_claude_settings() {
    local settings="$HOME/.claude/settings.json" shared="$HOME/.claude/settings.shared.json" merged
    if ! command -v jq >/dev/null; then
        echo "jq が無いため Claude Code 設定の合成をスキップしました(手動: jq -s '.[0] * .[1]' settings.json $shared)"
        return 0
    fi
    [[ -f "$settings" ]] || echo '{}' > "$settings"
    merged="$(jq -s '.[0] * .[1]' "$settings" "$shared")"
    [[ "$merged" == "$(jq . "$settings")" ]] && return 0
    printf '%s\n' "$merged" > "$settings.tmp" && mv "$settings.tmp" "$settings"
    echo "~/.claude/settings.json に settings.shared.json を合成しました"
}

# マシン固有の git ユーザー情報(~/.gitconfig から include される)
ensure_gitconfig_local() {
    [[ -f "$HOME/.gitconfig.local" ]] && return 0
    echo "~/.gitconfig.local がありません。git のユーザー情報を入力してください。"
    read -rp "  user.name : " git_name
    read -rp "  user.email: " git_email
    printf '[user]\n\tname = %s\n\temail = %s\n' "$git_name" "$git_email" > "$HOME/.gitconfig.local"
    echo "~/.gitconfig.local を作成しました"
}

# fisher と fish_plugins のプラグインを導入する(fish が無ければ何もしない)
ensure_fish_plugins() {
    command -v fish >/dev/null || return 0
    if ! fish -c 'functions -q fisher'; then
        fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
    fi
    fish -c 'fisher install < ~/.config/fish/fish_plugins'
}

# 既定シェルを fish にする(macOS のみ。Linux/WSL2 は必要なら手動: chsh -s "$(command -v fish)")
ensure_fish_default_shell() {
    [[ "$OS" == Darwin ]] || return 0
    local fish_path
    fish_path="$(command -v fish || true)"
    [[ -n "$fish_path" ]] || return 0
    dscl . -read ~/ UserShell | grep -qF "$fish_path" && return 0
    grep -qF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$fish_path"
    echo "既定シェルを fish にしました(再ログインで有効)"
}

diff_dotfiles() {
    if ! command -v stow >/dev/null; then
        echo "stow が未導入です(install 時に自動導入されます)"; return 0
    fi
    echo "## dotfiles 展開予定(stow dry-run)"
    stow --no --verbose=2 --no-folding --restow --target="$HOME" home 2>&1 | sed 's/^/  /'
}

status_dotfiles() {
    local rel target ok=0 total=0
    echo "## dotfiles(home/ -> \$HOME)"
    while IFS= read -r rel; do
        target="$HOME/$rel"
        total=$((total + 1))
        if [[ -e "$target" && "$target" -ef "home/$rel" ]]; then
            echo "  OK   $rel"; ok=$((ok + 1))
        elif [[ -e "$target" || -L "$target" ]]; then
            echo "  WARN $rel (存在するが repo を指していない)"
        else
            echo "  --   $rel (未展開)"
        fi
    done < <(cd home && find . -type f | sed 's|^\./||')
    echo "  同期: $ok/$total"
}

# ---------- main ----------
cmd="${1:-help}"
target="${2:-all}"
case "$cmd:$target" in
    install:all)      confirm_install all; install_packages; echo; install_dotfiles ;;
    install:dotfiles) confirm_install dotfiles; install_dotfiles ;;
    install:packages) confirm_install packages; install_packages ;;
    status:*)         status_dotfiles ;;
    diff:all)         diff_dotfiles; echo; diff_packages ;;
    diff:dotfiles)    diff_dotfiles ;;
    diff:packages)    diff_packages ;;
    dump:*)           dump_packages ;;
    help:*|-h:*|--help:*) usage ;;
    *) echo "不明なコマンド: $cmd $target"; echo; usage; exit 1 ;;
esac
