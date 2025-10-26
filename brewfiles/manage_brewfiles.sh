#!/bin/bash

# Homebrewパッケージ管理スクリプト
# このスクリプトは現在インストールされているHomebrewパッケージ、Caskアプリ、Mac App Storeアプリのリストを生成したり、それらからインストールを行います

set -e

# ディレクトリの確認
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 使用方法を表示する関数
show_usage() {
    echo "使用方法: $0 [generate|install]"
    echo ""
    echo "コマンド:"
    echo "  generate  現在のパッケージリストを生成（デフォルト）"
    echo "  install   生成されたリストからパッケージをインストール"
    echo ""
    echo "例:"
    echo "  $0          # パッケージリストを生成"
    echo "  $0 generate # パッケージリストを生成" 
    echo "  $0 install  # リストからパッケージをインストール"
    exit 1
}

# ファイルの存在確認
check_files_exist() {
    local missing_files=()
    
    if [[ ! -f "Brewfile" ]]; then
        missing_files+=("Brewfile")
    fi
    
    if [[ ! -f "Brewfile_cask" ]]; then
        missing_files+=("Brewfile_cask")
    fi
    
    if [[ ! -f "Masfiles" ]]; then
        missing_files+=("Masfiles")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo "❌ 以下のファイルが見つかりません:"
        printf '   %s\n' "${missing_files[@]}"
        echo ""
        echo "💡 まず './$(basename "$0") generate' を実行してファイルを生成してください"
        exit 1
    fi
}

# パッケージリストを生成する関数
generate_packages() {
    echo "🍺 Homebrew パッケージリストを生成しています..."

    # Brewfile の生成
    echo "📦 Homebrew formulae を生成中..."
    brew list --installed-on-request > Brewfile

    echo "✅ Brewfile が生成されました"

    # Brewfile_cask の生成
    echo "📱 Homebrew cask を生成中..."
    brew list --cask -1 > Brewfile_cask

    echo "✅ Brewfile_cask が生成されました"

    # Masfiles の生成（mas がインストールされている場合のみ）
    if command -v mas >/dev/null 2>&1; then
        echo "🍎 Mac App Store アプリを生成中..."
        mas list > Masfiles
        echo "✅ Masfiles が生成されました"
    else
        echo "⚠️  mas がインストールされていないため、Masfiles をスキップします"
        echo "   mas をインストールするには: brew install mas"
    fi

    echo ""
    echo "🎉 すべてのファイルが正常に生成されました！"
    echo ""
}

# パッケージをインストールする関数
install_packages() {
    echo "📦 Homebrewパッケージをインストールしています..."
    
    check_files_exist
    
    local install_count=0
    local skip_count=0
    
    # Homebrewパッケージのインストール
    echo "🔧 Homebrew formulae をインストール中..."
    while IFS= read -r line; do
        # コメント行や空行をスキップ
        if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
            continue
        fi
        
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
    
    # Caskアプリのインストール
    echo ""
    echo "🖥️  Homebrew cask をインストール中..."
    while IFS= read -r line; do
        # コメント行や空行をスキップ
        if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
            continue
        fi
        
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
    
    # Mac App Storeアプリのインストール
    if command -v mas >/dev/null 2>&1 && [[ -f "Masfiles" ]]; then
        echo ""
        echo "🍎 Mac App Store アプリをインストール中..."
        while IFS= read -r line; do
            # コメント行や空行をスキップ
            if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
                continue
            fi
            
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
    echo "🎉 インストールが完了しました！"
    echo "📊 結果: $install_count 個のパッケージをインストール、$skip_count 個をスキップ"
}

# コマンドライン引数の処理
MODE="${1:-generate}"

case "$MODE" in
    "generate")
        generate_packages
        ;;
    "install")
        install_packages
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        echo "❌ 無効なコマンド: $MODE"
        echo ""
        show_usage
        ;;
esac