#!/bin/bash

# 環境管理統合スクリプト
# dotfiles、brewfiles、developファイルの同期とセットアップを管理

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_usage() {
    echo "使用方法: $0 [generate|install|status] [all|dotfiles|brew|develop]"
    echo ""
    echo "コマンド:"
    echo "  generate  現在の設定を収集してリポジトリに保存"
    echo "  install   リポジトリから設定をシステムにインストール"
    echo "  status    現在の同期状態を確認"
    echo ""
    echo "対象："
    echo "  all       すべて（デフォルト）"
    echo "  dotfiles  設定ファイルのみ"
    echo "  brew      Homebrewパッケージのみ"
    echo "  develop   開発設定のみ"
    echo ""
    echo "例："
    echo "  $0 generate        # すべての設定を収集"
    echo "  $0 install dotfiles # dotfilesのみインストール"
    echo "  $0 status          # 同期状態を確認"
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
            
            # neovim設定
            if [[ -d "$HOME/.config/nvim" ]]; then
                mkdir -p "dotfiles/.config/nvim"
                cp -r "$HOME/.config/nvim/"* "dotfiles/.config/nvim/" 2>/dev/null || true
                echo "  ✅ neovim設定をコピーしました"
            fi
            
            # GitHub CLI設定
            if [[ -d "$HOME/.config/gh" ]]; then
                mkdir -p "dotfiles/.config/gh"
                cp -r "$HOME/.config/gh/"* "dotfiles/.config/gh/" 2>/dev/null || true
                echo "  ✅ GitHub CLI設定をコピーしました"
            fi
            
            # htop設定
            if [[ -d "$HOME/.config/htop" ]]; then
                mkdir -p "dotfiles/.config/htop"
                cp -r "$HOME/.config/htop/"* "dotfiles/.config/htop/" 2>/dev/null || true
                echo "  ✅ htop設定をコピーしました"
            fi
            ;;
            
        "install")
            echo "🏠 dotfiles をインストールしています..."
            
            # シンボリックリンクの作成
            for file in dotfiles/.*; do
                [[ "$file" == "dotfiles/." || "$file" == "dotfiles/.." ]] && continue
                [[ -f "$file" ]] || continue
                
                local basename=$(basename "$file")
                local target="$HOME/$basename"
                
                if [[ -L "$target" ]]; then
                    echo "  ⏭️  $basename (既にシンボリックリンク)"
                elif [[ -f "$target" ]]; then
                    echo "  🔄 $basename をバックアップして置き換え"
                    mv "$target" "${target}.backup.$(date +%Y%m%d_%H%M%S)"
                    ln -s "$SCRIPT_DIR/$file" "$target"
                    echo "  ✅ $basename をリンクしました"
                else
                    ln -s "$SCRIPT_DIR/$file" "$target"
                    echo "  ✅ $basename をリンクしました"
                fi
            done
            
            # .configディレクトリの処理
            if [[ -d "dotfiles/.config" ]]; then
                mkdir -p "$HOME/.config"
                
                # fish設定
                if [[ -d "dotfiles/.config/fish" ]]; then
                    if [[ -L "$HOME/.config/fish" ]]; then
                        echo "  ⏭️  fish設定 (既にシンボリックリンク)"
                    else
                        [[ -d "$HOME/.config/fish" ]] && mv "$HOME/.config/fish" "$HOME/.config/fish.backup.$(date +%Y%m%d_%H%M%S)"
                        ln -s "$SCRIPT_DIR/dotfiles/.config/fish" "$HOME/.config/fish"
                        echo "  ✅ fish設定をリンクしました"
                    fi
                fi
                
                # neovim設定
                if [[ -d "dotfiles/.config/nvim" ]]; then
                    if [[ -L "$HOME/.config/nvim" ]]; then
                        echo "  ⏭️  neovim設定 (既にシンボリックリンク)"
                    else
                        [[ -d "$HOME/.config/nvim" ]] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
                        ln -s "$SCRIPT_DIR/dotfiles/.config/nvim" "$HOME/.config/nvim"
                        echo "  ✅ neovim設定をリンクしました"
                    fi
                fi
                
                # GitHub CLI設定
                if [[ -d "dotfiles/.config/gh" ]]; then
                    if [[ -L "$HOME/.config/gh" ]]; then
                        echo "  ⏭️  GitHub CLI設定 (既にシンボリックリンク)"
                    else
                        [[ -d "$HOME/.config/gh" ]] && mv "$HOME/.config/gh" "$HOME/.config/gh.backup.$(date +%Y%m%d_%H%M%S)"
                        ln -s "$SCRIPT_DIR/dotfiles/.config/gh" "$HOME/.config/gh"
                        echo "  ✅ GitHub CLI設定をリンクしました"
                    fi
                fi
                
                # htop設定
                if [[ -d "dotfiles/.config/htop" ]]; then
                    if [[ -L "$HOME/.config/htop" ]]; then
                        echo "  ⏭️  htop設定 (既にシンボリックリンク)"
                    else
                        [[ -d "$HOME/.config/htop" ]] && mv "$HOME/.config/htop" "$HOME/.config/htop.backup.$(date +%Y%m%d_%H%M%S)"
                        ln -s "$SCRIPT_DIR/dotfiles/.config/htop" "$HOME/.config/htop"
                        echo "  ✅ htop設定をリンクしました"
                    fi
                fi
            fi
            ;;
    esac
}

# Homebrew管理
manage_brew() {
    local action="$1"
    cd "$SCRIPT_DIR/brewfiles"
    
    case "$action" in
        "generate")
            echo "🍺 Homebrew パッケージリストを生成しています..."
            
            # Brewfile の生成
            echo "📦 Homebrew formulae を生成中..."
            brew list --installed-on-request > Brewfile
            echo "✅ Brewfile が生成されました"
            
            # Brewfile_cask の生成
            echo "📱 Homebrew cask を生成中..."
            brew list --cask -1 > Brewfile_cask
            echo "✅ Brewfile_cask が生成されました"
            
            # Masfiles の生成
            if command -v mas >/dev/null 2>&1; then
                echo "🍎 Mac App Store アプリを生成中..."
                mas list > Masfiles
                echo "✅ Masfiles が生成されました"
            else
                echo "⚠️  mas がインストールされていないため、Masfiles をスキップします"
            fi
            ;;
            
        "install")
            echo "🍺 Homebrew パッケージをインストールしています..."
            
            local install_count=0
            local skip_count=0
            
            # Homebrewパッケージのインストール
            if [[ -f "Brewfile" ]]; then
                echo "🔧 Homebrew formulae をインストール中..."
                while IFS= read -r line; do
                    [[ -z "$line" ]] && continue
                    
                    if brew list "$line" &>/dev/null; then
                        echo "  ⏭️  $line (既にインストール済み)"
                        ((skip_count++))
                    else
                        echo "  ⬇️  $line をインストール中..."
                        if brew install "$line"; then
                            echo "  ✅ $line をインストールしました"
                            ((install_count++))
                        else
                            echo "  ❌ $line のインストールに失敗しました"
                        fi
                    fi
                done < Brewfile
            fi
            
            # Caskアプリのインストール
            if [[ -f "Brewfile_cask" ]]; then
                echo ""
                echo "�️  Homebrew cask をインストール中..."
                while IFS= read -r line; do
                    [[ -z "$line" ]] && continue
                    
                    if brew list --cask "$line" &>/dev/null; then
                        echo "  ⏭️  $line (既にインストール済み)"
                        ((skip_count++))
                    else
                        echo "  ⬇️  $line をインストール中..."
                        if brew install --cask "$line"; then
                            echo "  ✅ $line をインストールしました"
                            ((install_count++))
                        else
                            echo "  ❌ $line のインストールに失敗しました"
                        fi
                    fi
                done < Brewfile_cask
            fi
            
            # Mac App Storeアプリのインストール
            if command -v mas >/dev/null 2>&1 && [[ -f "Masfiles" ]]; then
                echo ""
                echo "🍎 Mac App Store アプリをインストール中..."
                while IFS= read -r line; do
                    [[ -z "$line" ]] && continue
                    
                    # ID部分を抽出（行の最初の数字部分）
                    if [[ "$line" =~ ^([0-9]+) ]]; then
                        local app_id="${BASH_REMATCH[1]}"
                        local app_name=$(echo "$line" | sed 's/^[0-9]* *//' | sed 's/ *(.*)$//')
                        
                        if mas list | grep -q "^$app_id"; then
                            echo "  ⏭️  $app_name (既にインストール済み)"
                            ((skip_count++))
                        else
                            echo "  ⬇️  $app_name をインストール中..."
                            if mas install "$app_id"; then
                                echo "  ✅ $app_name をインストールしました"
                                ((install_count++))
                            else
                                echo "  ❌ $app_name のインストールに失敗しました"
                            fi
                        fi
                    fi
                done < Masfiles
            else
                echo ""
                echo "⚠️  mas がインストールされていないため、Mac App Store アプリのインストールをスキップします"
            fi
            
            echo ""
            echo "📊 結果: $install_count 個のパッケージをインストール、$skip_count 個をスキップ"
            ;;
    esac
    
    cd "$SCRIPT_DIR"
}

# 開発設定管理
manage_develop() {
    local action="$1"
    
    case "$action" in
        "generate")
            echo "💻 開発設定を収集しています..."
            
            # developディレクトリが存在しない場合は作成
            mkdir -p "develop"
            
            # よく使われる設定ファイルをチェック
            local dev_files=(
                ".prettierrc"
                ".prettierignore"
                "eslint.config.js"
            )
            
            for file in "${dev_files[@]}"; do
                if [[ -f "$HOME/$file" ]]; then
                    cp "$HOME/$file" "develop/$file"
                    echo "  ✅ $file をコピーしました"
                fi
            done
            
            # プロジェクトルートの設定ファイルもチェック（存在する場合のみ）
            local project_files=(
                ".gitignore"
            )
            
            for file in "${project_files[@]}"; do
                if [[ -f "$file" ]]; then
                    cp "$file" "develop/$file"
                    echo "  ✅ $file をコピーしました"
                fi
            done
            ;;
            
        "install")
            echo "💻 開発設定をインストールしています..."
            
            for file in develop/*; do
                [[ -f "$file" ]] || continue
                local basename=$(basename "$file")
                local target="$HOME/$basename"
                
                if [[ -f "$target" ]]; then
                    echo "  🔄 $basename を更新"
                    cp "$file" "$target"
                else
                    cp "$file" "$target"
                    echo "  ✅ $basename をコピーしました"
                fi
            done
            ;;
    esac
}

# 同期状態確認
check_status() {
    echo "📊 環境同期状態を確認しています..."
    echo ""
    
    # dotfiles状態確認
    echo "🏠 dotfiles:"
    local dotfiles_synced=0
    local dotfiles_total=0
    
    for file in dotfiles/.*; do
        [[ "$file" == "dotfiles/." || "$file" == "dotfiles/.." ]] && continue
        [[ -f "$file" ]] || continue
        
        ((dotfiles_total++))
        local basename=$(basename "$file")
        local target="$HOME/$basename"
        
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$SCRIPT_DIR/$file" ]]; then
            echo "  ✅ $basename"
            ((dotfiles_synced++))
        elif [[ -f "$target" ]]; then
            echo "  ⚠️  $basename (ファイルは存在するがリンクされていません)"
        else
            echo "  ❌ $basename (未インストール)"
        fi
    done
    
    echo "     同期率: $dotfiles_synced/$dotfiles_total"
    echo ""
    
    # brewfiles状態確認
    echo "🍺 brewfiles:"
    if [[ -f "brewfiles/Brewfile" ]]; then
        local brew_count=$(wc -l < "brewfiles/Brewfile" | tr -d ' ')
        echo "  📦 Homebrew formulae: $brew_count 個"
    fi
    
    if [[ -f "brewfiles/Brewfile_cask" ]]; then
        local cask_count=$(wc -l < "brewfiles/Brewfile_cask" | tr -d ' ')
        echo "  🖥️  Homebrew cask: $cask_count 個"
    fi
    
    if [[ -f "brewfiles/Masfiles" ]]; then
        local mas_count=$(wc -l < "brewfiles/Masfiles" | tr -d ' ')
        echo "  🍎 Mac App Store: $mas_count 個"
    fi
    
    echo ""
    
    # develop状態確認
    echo "💻 develop:"
    if [[ -d "develop" ]]; then
        local dev_count=$(find develop -type f | wc -l | tr -d ' ')
        echo "  📄 設定ファイル: $dev_count 個"
        
        for file in develop/*; do
            [[ -f "$file" ]] || continue
            local basename=$(basename "$file")
            if [[ -f "$HOME/$basename" ]]; then
                echo "  ✅ $basename"
            else
                echo "  ❌ $basename (未インストール)"
            fi
        done
    else
        echo "  ⚠️  developディレクトリが見つかりません"
    fi
}

# メイン処理
ACTION="${1:-generate}"
TARGET="${2:-all}"

case "$ACTION" in
    "generate")
        case "$TARGET" in
            "all")
                manage_dotfiles generate
                echo ""
                manage_brew generate
                echo ""
                manage_develop generate
                ;;
            "dotfiles") manage_dotfiles generate ;;
            "brew") manage_brew generate ;;
            "develop") manage_develop generate ;;
            *) show_usage ;;
        esac
        ;;
        
    "install")
        case "$TARGET" in
            "all")
                manage_brew install
                echo ""
                manage_dotfiles install
                echo ""
                manage_develop install
                ;;
            "dotfiles") manage_dotfiles install ;;
            "brew") manage_brew install ;;
            "develop") manage_develop install ;;
            *) show_usage ;;
        esac
        ;;
        
    "status")
        check_status
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