#!/bin/bash
# ブートストラップ: git を用意して clone し、あとは setup.sh に渡す。
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/asiball/dotfiles/main/install.sh)"
# setup.sh は対話入力を含むため、curl | bash ではなく上の形式で実行する(stdin を端末に残す)
set -eu

REPO="https://github.com/asiball/dotfiles.git"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"

case "$(uname -s)" in
    Darwin)
        # クリーンな macOS では /usr/bin/git がスタブとして存在するので、CLT の有無で判定する
        if ! xcode-select -p >/dev/null 2>&1; then
            read -rp "git がありません。Xcode Command Line Tools を導入しますか? [y/N] " ans
            [[ "$ans" =~ ^[Yy]$ ]] || { echo "中止しました"; exit 1; }
            xcode-select --install 2>/dev/null || true
            until xcode-select -p >/dev/null 2>&1; do sleep 5; done
        fi
        ;;
    Linux)
        if ! command -v git >/dev/null; then
            read -rp "git がありません。apt で導入しますか? [y/N] " ans
            [[ "$ans" =~ ^[Yy]$ ]] || { echo "中止しました"; exit 1; }
            sudo apt-get update && sudo apt-get install -y git
        fi
        ;;
esac

if [[ -d "$DOTFILES" ]]; then
    echo "$DOTFILES は既にあります(clone をスキップ)"
else
    git clone "$REPO" "$DOTFILES"
fi

exec "$DOTFILES/setup.sh" install all
