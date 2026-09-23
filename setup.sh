#!/bin/bash
# dotfiles セットアップ HUB。ロジックは stow / brew bundle / apt に委譲する。
# macOS の /bin/bash(3.2)でも動かすため、mapfile や set -u 下での空配列展開を使わない
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
OS="$(uname -s)"   # Darwin | Linux
TS="$(date +%Y%m%d_%H%M%S)"
BACKUPS=()         # この実行で退避したファイル(元のパス)。最後にまとめて表示する

usage() {
    cat <<USAGE
使い方: $0 <command> [target...]

  install [target...]  リポジトリから展開する(既定: all)
  list                 管理している設定の一覧(stow パッケージ・ファイル・付随処理)
  status               dotfiles の同期状態を表示する
  diff    [target...]  実環境との差分を表示する(stow は dry-run)
  dump                 実環境の brew パッケージを Brewfile に書き出す(macOS)

target:
  all        packages + dotfiles
  dotfiles   home/ の全 stow パッケージ
  packages   macOS は brew bundle、Linux(Ubuntu/WSL2)は apt-packages.txt
  <名前>     home/<名前>/ の stow パッケージだけ($(stow_packages | xargs))

環境変数:
  MAS=1   Mac App Store アプリ(Brewfile.mas)も対象に含める(要サインイン)
USAGE
}

# 既存ファイルを <path>.backup.<時刻> に退避し、記録する(finish でまとめて表示)
backup() {
    mv "$1" "$1.backup.$TS"
    BACKUPS+=("$1")
    echo "  退避: $1 -> $1.backup.$TS"
}

# stow と衝突するパスを片付ける。リンク切れの symlink(レイアウト変更前の repo を指していたもの等)は中身が無いので削除、それ以外は退避
clear_path() {
    if [[ -L "$1" && ! -e "$1" ]]; then
        echo "  リンク切れを削除: $1 (-> $(readlink "$1"))"
        rm "$1"
    else
        backup "$1"
    fi
}

# 引数(target...)を WITH_PACKAGES(0/1)と PKGS(stow パッケージ名の配列)に展開する
resolve_targets() {
    local t
    WITH_PACKAGES=0
    PKGS=()
    for t in "$@"; do
        case "$t" in
            all)      WITH_PACKAGES=1; PKGS+=($(stow_packages)) ;;
            dotfiles) PKGS+=($(stow_packages)) ;;
            packages) WITH_PACKAGES=1 ;;
            *)
                stow_packages | grep -qxF -- "$t" || { echo "不明な対象: $t(一覧は $0 list)"; exit 1; }
                PKGS+=("$t")
                ;;
        esac
    done
}

# 実行前に、インストールされるもの・変更されるものを列挙して確認を取る
confirm_install() {
    local pkg desc
    echo "これから行うこと:"
    if [[ "$WITH_PACKAGES" == 1 ]]; then
        case "$OS" in
            Darwin) echo "  - Homebrew+ brew bundle: Brewfile$(mas_enabled && echo ', Brewfile.mas')" ;;
            Linux)  echo "  - apt でインストール: $(apt_packages)" ;;
        esac
    fi
    if [[ ${#PKGS[@]} -gt 0 ]]; then
        echo "  - stow で \$HOME に展開: ${PKGS[*]}"
        echo "    衝突する既存ファイル・symlink は <元のパス>.backup.$TS に退避、リンク切れの symlink は削除"
        for pkg in "${PKGS[@]}"; do
            desc="$(extra_desc "$pkg")"
            if [[ -n "$desc" ]]; then echo "  - $pkg: $desc"; fi
        done
    fi
    read -rp "続行しますか? [y/N] " ans || true   # stdin が端末でなく EOF のときも下で中止扱いにする
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "中止しました"; exit 1; }
}

# ---------- packages ----------
ensure_homebrew() {
    command -v brew >/dev/null && return 0
    echo "Homebrew をインストールします..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
    if [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi
}

mas_enabled() { [[ "${MAS:-}" == 1 ]] && command -v mas >/dev/null; }

apt_packages() { grep -v '^#' apt-packages.txt | xargs; }
apt_install()  { sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"; }   # tzdata 等の debconf 対話を出さない

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
# home/ 直下のディレクトリがそれぞれ stow パッケージ(ツール単位)
stow_packages() { local d; for d in home/*/; do d="${d%/}"; echo "${d#home/}"; done; }
pkg_files()     { (cd "home/$1" && find . -type f | sed 's|^\./||' | sort); }

# stow 以外に行う処理の説明(list / 確認表示用)と実行。パッケージ名で対応づける
extra_desc() {
    case "$1" in
        git)    echo "~/.gitconfig.local が無ければ作成(user.name / user.email を入力)" ;;
        claude) echo "settings.shared.json(hooks, statusLine)を ~/.claude/settings.json に合成(jq。変更時は退避)" ;;
        fish)   echo "fisher とプラグインをインストール$([[ "$OS" == Darwin ]] && echo '、既定シェルを fish に変更')" ;;
        tmux)   echo "~/.tmux.conf があれば退避(~/.config/tmux/tmux.conf を使うため)" ;;
    esac
}
post_install() {
    case "$1" in
        git)    ensure_gitconfig_local ;;
        claude) ensure_claude_settings ;;
        fish)   ensure_fish_plugins; ensure_fish_default_shell ;;
        tmux)   retire_tmux_conf ;;
    esac
}

ensure_stow() {
    command -v stow >/dev/null && return 0
    echo "GNU stow をインストールします..."
    case "$OS" in
        Darwin) ensure_homebrew; brew install stow ;;
        Linux)  apt_install stow ;;
    esac
}

install_dotfiles() {
    local pkg rel target dir
    ensure_stow
    echo "## dotfiles を展開: ${PKGS[*]}"
    # 衝突する既存ファイル(repo 以外を指す symlink を含む)を片付けてから展開する。
    # 親ディレクトリが symlink(~/.config/fish をディレクトリごと張っていた等)の場合も stow は衝突するので対象にする
    for pkg in "${PKGS[@]}"; do
        while IFS= read -r rel; do
            dir="$(dirname "$rel")"
            while [[ "$dir" != . ]]; do
                if [[ -L "$HOME/$dir" ]]; then clear_path "$HOME/$dir"; fi
                dir="$(dirname "$dir")"
            done
            target="$HOME/$rel"
            if [[ -e "$target" || -L "$target" ]] && [[ ! "$target" -ef "home/$pkg/$rel" ]]; then
                clear_path "$target"
            fi
        done < <(pkg_files "$pkg")
    done
    # --no-folding: ディレクトリは実体で作り、ファイルだけ symlink にする
    # (~/.config/fish が repo への symlink に畳まれると fisher 等が repo 内に書き込むため)
    stow --no-folding --restow --dir=home --target="$HOME" "${PKGS[@]}"
    echo "  $HOME に展開しました"

    for pkg in "${PKGS[@]}"; do post_install "$pkg"; done
}

# ~/.tmux.conf が残っていると ~/.config/tmux/tmux.conf が読まれない
retire_tmux_conf() {
    if [[ -e "$HOME/.tmux.conf" || -L "$HOME/.tmux.conf" ]]; then backup "$HOME/.tmux.conf"; fi
}

# home/claude/.claude/settings.shared.json(hooks, statusLine など)を ~/.claude/settings.json に合成する。
# settings.json 自体は環境依存値や機密を含むため repo 管理外。shared 側の項目で上書きし(同名キーは配列ごと置換)、それ以外は保持する
ensure_claude_settings() {
    local settings="$HOME/.claude/settings.json" shared="$HOME/.claude/settings.shared.json" merged
    if ! command -v jq >/dev/null; then
        echo "jq が無いため Claude Code 設定の合成をスキップしました(手動: jq -s '.[0] * .[1]' settings.json $shared)"
        return 0
    fi
    if [[ -f "$settings" ]]; then
        merged="$(jq -s '.[0] * .[1]' "$settings" "$shared")"
        [[ "$merged" == "$(jq . "$settings")" ]] && return 0
        backup "$settings"
    else
        merged="$(jq . "$shared")"
    fi
    printf '%s\n' "$merged" > "$settings"
    echo "  ~/.claude/settings.json に settings.shared.json を合成しました"
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

# fisher と fish_plugins のプラグインをインストールする(fish が無ければ何もしない)
ensure_fish_plugins() {
    command -v fish >/dev/null || return 0
    if ! fish -c 'functions -q fisher'; then
        # fisher は stdin が端末でないとプラグイン名として読むので、後続の入力(git のユーザー情報等)を食わないよう塞ぐ
        fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher' </dev/null
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
        echo "stow が未インストールです(install 時に自動インストールされます)"; return 0
    fi
    echo "## dotfiles 展開予定(stow dry-run): ${PKGS[*]}"
    stow --no --verbose=2 --no-folding --restow --dir=home --target="$HOME" "${PKGS[@]}" 2>&1 | sed 's/^/  /'
}

list_packages() {
    local pkg desc
    echo "## dotfiles(home/<名前>/ -> \$HOME。個別に展開: $0 install <名前>)"
    for pkg in $(stow_packages); do
        echo "  $pkg"
        pkg_files "$pkg" | sed 's|^|      ~/|'
        desc="$(extra_desc "$pkg")"
        if [[ -n "$desc" ]]; then echo "      + $desc"; fi
    done
    echo "## パッケージ($0 install packages)"
    echo "  macOS(Brewfile): $(sed -nE 's/^(brew|cask) "([^"]+)".*/\2/p' Brewfile | xargs)"
    echo "  macOS(Brewfile.mas, MAS=1 のとき): $(grep -c '^mas ' Brewfile.mas) 件"
    echo "  Linux(apt-packages.txt): $(apt_packages)"
}

status_dotfiles() {
    local pkg rel target ok=0 total=0
    echo "## dotfiles(home/<名前>/ -> \$HOME)"
    for pkg in $(stow_packages); do
        while IFS= read -r rel; do
            target="$HOME/$rel"
            total=$((total + 1))
            if [[ -e "$target" && "$target" -ef "home/$pkg/$rel" ]]; then
                printf '  OK   %-7s %s\n' "$pkg" "$rel"; ok=$((ok + 1))
            elif [[ -e "$target" || -L "$target" ]]; then
                printf '  WARN %-7s %s (存在するが repo を指していない)\n' "$pkg" "$rel"
            else
                printf '  --   %-7s %s (未展開)\n' "$pkg" "$rel"
            fi
        done < <(pkg_files "$pkg")
    done
    echo "  同期: $ok/$total"
}

finish() {
    local f
    echo; echo "==== セットアップ完了 ===="
    if [[ ${#BACKUPS[@]} -gt 0 ]]; then
        echo "既存ファイルを退避しました(${#BACKUPS[@]} 件。戻すには mv <退避先> <元のパス>):"
        for f in "${BACKUPS[@]}"; do echo "  $f -> $f.backup.$TS"; done
    else
        echo "退避したファイルはありません"
    fi
    status_dotfiles | tail -1
}

# ---------- main ----------
cmd="${1:-help}"
[[ $# -gt 0 ]] && shift
[[ $# -gt 0 ]] || set -- all
case "$cmd" in
    install)
        resolve_targets "$@"
        confirm_install
        if [[ "$WITH_PACKAGES" == 1 ]]; then install_packages; echo; fi
        if [[ ${#PKGS[@]} -gt 0 ]]; then install_dotfiles; fi
        finish
        ;;
    diff)
        resolve_targets "$@"
        if [[ ${#PKGS[@]} -gt 0 ]]; then diff_dotfiles; echo; fi
        if [[ "$WITH_PACKAGES" == 1 ]]; then diff_packages; fi
        ;;
    list)           list_packages ;;
    status)         status_dotfiles ;;
    dump)           dump_packages ;;
    help|-h|--help) usage ;;
    *) echo "不明なコマンド: $cmd"; echo; usage; exit 1 ;;
esac
