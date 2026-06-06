#!/bin/bash

# 環境管理統合スクリプト
# dotfiles(stow) と Homebrew(brew bundle) の収集・展開を束ねる HUB

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_usage() {
    echo "使用方法: $0 [generate|install|status|diff] [all|dotfiles|brew]"
    echo ""
    echo "コマンド:"
    echo "  generate  現在の設定を収集してリポジトリに保存"
    echo "  install   リポジトリから設定をシステムにインストール"
    echo "  status    現在の同期状態を確認"
    echo "  diff      現在の環境とコンフィグファイルの差分を表示"
    echo ""
    echo "対象："
    echo "  all       すべて（デフォルト）"
    echo "  dotfiles  設定ファイルのみ（stow で展開）"
    echo "  brew      Homebrewパッケージのみ（brew bundle）"
    echo ""
    echo "例："
    echo "  $0 install all      # Homebrew導入→パッケージ→dotfiles を一括展開"
    echo "  $0 generate         # 現在の設定をリポジトリに収集"
    echo "  $0 install dotfiles # dotfilesのみ stow で展開"
    echo "  $0 status           # 同期状態を確認"
    echo "  $0 diff brew        # Homebrewパッケージの差分を表示"
    echo ""
    echo "環境変数:"
    echo "  MAS=1     Mac App Store アプリも対象に含める（既定はスキップ。要サインイン）"
    echo ""
    echo "※ eslint/prettier テンプレートは templates/ に静置き（手動コピーで利用）"
}

# dotfiles管理
manage_dotfiles() {
    local action="$1"
    
    case "$action" in
        "generate")
            echo "🏠 dotfiles を収集しています..."
            
            # dotfilesディレクトリが存在しない場合は作成
            mkdir -p "dotfiles/.config/fish"
            
            # ホームディレクトリの設定ファイルをコピー
            local dotfiles=(
                ".bashrc"
                ".gitconfig"
                ".tmuxrc"
                ".vimrc"
                ".zshrc"
            )
            
            for file in "${dotfiles[@]}"; do
                if [[ -f "$HOME/$file" ]]; then
                    cp "$HOME/$file" "dotfiles/$file"
                    echo "  ✅ $file をコピーしました"
                else
                    echo "  ⚠️  $HOME/$file が見つかりません"
                fi
            done
            
            # .configディレクトリの処理
            if [[ -d "$HOME/.config/fish" ]]; then
                if [[ -f "$HOME/.config/fish/config.fish" ]]; then
                    cp "$HOME/.config/fish/config.fish" "dotfiles/.config/fish/"
                    echo "  ✅ fish/config.fish をコピーしました"
                fi
                if [[ -f "$HOME/.config/fish/fish_plugins" ]]; then
                    cp "$HOME/.config/fish/fish_plugins" "dotfiles/.config/fish/"
                    echo "  ✅ fish/fish_plugins をコピーしました"
                fi
            fi
            ;;
            
        "install")
            echo "🏠 dotfiles をインストールしています (stow に委譲)..."
            ensure_stow

            # ~/.config 全体が repo へ折り畳まれるのを防ぐため、親を実体で用意
            mkdir -p "$HOME/.config"

            # 競合退避: stow が管理する各リーフについて、対応する $HOME 側が
            # 実体（非symlink）なら *.backup.<timestamp> へ退避する
            local timestamp
            timestamp=$(date +%Y%m%d_%H%M%S)
            local leaf rel target
            while IFS= read -r leaf; do
                rel="${leaf#"$SCRIPT_DIR"/dotfiles/}"
                target="$HOME/$rel"
                if [[ -e "$target" && ! -L "$target" ]]; then
                    mkdir -p "$(dirname "$target")"
                    mv "$target" "${target}.backup.${timestamp}"
                    echo "  💾 $rel を退避しました"
                fi
            done < <(find "$SCRIPT_DIR/dotfiles" -type f)

            # シンボリックリンクを stow で作成（既存リンクは張り直す）
            stow --restow --target="$HOME" --dir="$SCRIPT_DIR" dotfiles
            echo "  ✅ dotfiles をリンクしました"
            ;;
    esac
}

# Homebrew 本体を用意する（クリーンmacOS対応）
ensure_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi

    echo "🍺 Homebrew が見つかりません。公式インストーラで導入します..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # PATH を通す（Apple Silicon / Intel 両対応）
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

# stow を用意する（dotfiles 展開の前提）
ensure_stow() {
    command -v stow >/dev/null 2>&1 && return 0
    ensure_homebrew
    echo "📦 GNU stow を導入します..."
    brew install stow
}

# Mac App Store アプリ(Brewfile.mas)を処理すべきか。
# 既定はスキップ。MAS=1 かつ mas 導入済みのときだけ true。
mas_enabled() {
    [[ "${MAS:-}" == "1" ]] && command -v mas >/dev/null 2>&1
}

# Homebrew管理（brew bundle に委譲）
manage_brew() {
    local action="$1"
    local brewfile="$SCRIPT_DIR/brewfiles/Brewfile"
    local masfile="$SCRIPT_DIR/brewfiles/Brewfile.mas"

    case "$action" in
        "generate")
            echo "🍺 Brewfile を生成しています..."
            brew bundle dump --force --no-vscode --no-mas --file="$brewfile"
            echo "✅ Brewfile を生成しました ($brewfile)"

            if mas_enabled; then
                brew bundle dump --force --no-vscode --mas \
                    --no-formulae --no-casks --no-taps --file="$masfile"
                echo "✅ Brewfile.mas を生成しました ($masfile)"
            else
                echo "ℹ️  mas はスキップしました（Brewfile.mas は保持）。収集するには MAS=1（要サインイン）"
            fi
            ;;

        "install")
            echo "🍺 Brewfile からインストールしています..."
            ensure_homebrew
            # --no-upgrade: インストール済みは更新せずスキップ（従来の挙動を踏襲）
            brew bundle install --no-upgrade --file="$brewfile"

            if mas_enabled; then
                echo "🍎 Mac App Store アプリをインストールしています..."
                brew bundle install --no-upgrade --file="$masfile"
            else
                echo "ℹ️  Mac App Store アプリはスキップしました（含めるには MAS=1、要サインイン）"
            fi
            ;;
    esac
}

# 環境とファイルの差分確認（brew bundle に委譲）
show_brew_diff() {
    local brewfile="$SCRIPT_DIR/brewfiles/Brewfile"
    local masfile="$SCRIPT_DIR/brewfiles/Brewfile.mas"
    echo "🍺 Homebrew パッケージ差分:"

    if [[ ! -f "$brewfile" ]]; then
        echo "  ⚠️  Brewfile が見つかりません"
        return
    fi

    echo "  ➖ Brewfile にあるが未インストール:"
    brew bundle check --verbose --file="$brewfile" 2>&1 | sed 's/^/    /'

    echo ""
    echo "  ➕ インストール済みだが Brewfile にない (cleanup 候補):"
    brew bundle cleanup --file="$brewfile" 2>&1 | sed 's/^/    /'

    if mas_enabled; then
        echo ""
        echo "  🍎 Mac App Store (Brewfile.mas):"
        brew bundle check --verbose --file="$masfile" 2>&1 | sed 's/^/    /'
    fi
}

show_dotfiles_diff() {
    echo "🏠 dotfiles 差分 (stow dry-run):"
    if ! command -v stow >/dev/null 2>&1; then
        echo "  ⚠️  stow が未インストールです（install 実行時に自動導入されます）"
        return
    fi
    # --no: 実際には変更せず、予定アクション/競合のみ表示
    stow --no --verbose=2 --restow --target="$HOME" --dir="$SCRIPT_DIR" dotfiles 2>&1 | sed 's/^/  /'
}

# 同期状態確認
check_status() {
    echo "📊 環境同期状態を確認しています..."
    echo ""
    
    # dotfiles状態確認（.config 配下のネストも含めて走査）
    echo "🏠 dotfiles:"
    local dotfiles_synced=0
    local dotfiles_total=0
    local leaf rel target

    while IFS= read -r leaf; do
        rel="${leaf#"$SCRIPT_DIR"/dotfiles/}"
        target="$HOME/$rel"
        dotfiles_total=$((dotfiles_total + 1))

        # -ef: 相対/絶対どちらの symlink でも同一実体かを inode で判定
        if [[ -L "$target" ]] && [[ "$target" -ef "$leaf" ]]; then
            echo "  ✅ $rel"
            dotfiles_synced=$((dotfiles_synced + 1))
        elif [[ -e "$target" || -L "$target" ]]; then
            echo "  ⚠️  $rel (存在するが repo を指していません)"
        else
            echo "  ❌ $rel (未インストール)"
        fi
    done < <(find "$SCRIPT_DIR/dotfiles" -type f)

    echo "     同期率: $dotfiles_synced/$dotfiles_total"
    echo ""
    
    # brewfiles状態確認
    echo "🍺 brewfiles:"
    if [[ -f "brewfiles/Brewfile" ]]; then
        local brew_count cask_count mas_count=0
        brew_count=$(grep -c '^brew ' "brewfiles/Brewfile" || true)
        cask_count=$(grep -c '^cask ' "brewfiles/Brewfile" || true)
        [[ -f "brewfiles/Brewfile.mas" ]] && mas_count=$(grep -c '^mas ' "brewfiles/Brewfile.mas" || true)
        echo "  📦 Homebrew formulae: $brew_count 個"
        echo "  🖥️  Homebrew cask: $cask_count 個"
        echo "  🍎 Mac App Store: $mas_count 個 (Brewfile.mas, 既定スキップ)"
    else
        echo "  ⚠️  Brewfile が見つかりません"
    fi

    echo ""
}

# メイン処理
ACTION="${1:-help}"
TARGET="${2:-all}"

case "$ACTION" in
    "generate")
        case "$TARGET" in
            "all")
                manage_dotfiles generate
                echo ""
                manage_brew generate
                ;;
            "dotfiles") manage_dotfiles generate ;;
            "brew") manage_brew generate ;;
            *) show_usage ;;
        esac
        ;;

    "install")
        case "$TARGET" in
            "all")
                manage_brew install
                echo ""
                manage_dotfiles install
                ;;
            "dotfiles") manage_dotfiles install ;;
            "brew") manage_brew install ;;
            *) show_usage ;;
        esac
        ;;

    "status")
        check_status
        ;;

    "diff")
        case "$TARGET" in
            "all")
                show_dotfiles_diff
                echo ""
                show_brew_diff
                ;;
            "dotfiles") show_dotfiles_diff ;;
            "brew") show_brew_diff ;;
            *) show_usage ;;
        esac
        ;;
        
    "help"|"-h"|"--help")
        show_usage
        ;;
        
    *)
        echo "❌ 無効なコマンド: $ACTION"
        show_usage
        ;;
esac

echo ""
echo "🎉 操作が完了しました！"