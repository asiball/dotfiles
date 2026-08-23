#!/bin/bash
# クリーンな Ubuntu コンテナで install.sh(→ setup.sh install all)を 2 回流し、更新と冪等性を確認する。
# 対象はコミット済みの HEAD。repo は read-only でマウントするので、repo 内への書き込みがあれば失敗する。
#   使い方: test/run.sh
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
img="$(docker build -q "$ROOT/test")"
docker run --rm -v "$ROOT:/src:ro" "$img" bash -c '
    set -eu
    echo "### 1 回目(クリーン環境)"
    printf "y\nTest User\ntest@example.com\n" | REPO=/src bash /src/install.sh
    n1=$(find ~ -name "*.backup.*" | wc -l)
    echo; echo "### 2 回目(更新 + 再展開)"
    printf "y\n" | bash ~/dotfiles/install.sh
    n2=$(find ~ -name "*.backup.*" | wc -l)
    echo; echo "### 退避ファイル数: 1 回目=$n1 / 2 回目=$n2(同じなら OK)"
    [ "$n1" = "$n2" ]
    ~/dotfiles/setup.sh status | tail -1
    echo "### OK"
'
