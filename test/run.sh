#!/bin/bash
# クリーンな Ubuntu コンテナで install.sh(→ setup.sh install all)を 2 回流し、更新と冪等性を確認する。
# 対象はコミット済みの HEAD(/src を read-only でマウントし、install.sh が ~/dotfiles に clone する)。
# 判定: 2 回目に退避が増えない / 全ファイルが同期済み / clone に差分が無い(fisher 等が repo 内へ書き込んでいない)
#   使い方: test/run.sh
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
img="$(docker build -q "$ROOT/test")"
docker run --rm -v "$ROOT:/src:ro" "$img" bash -c '
    set -eu
    echo "### 1 回目(クリーン環境)"
    printf "y\ny\nTest User\ntest@example.com\n" | REPO=/src bash /src/install.sh   # git 導入の確認 / setup の確認 / git user.name / user.email
    n1=$(find ~ -name "*.backup.*" | wc -l)
    echo; echo "### 2 回目(更新 + 再展開)"
    printf "y\n" | bash ~/dotfiles/install.sh
    n2=$(find ~ -name "*.backup.*" | wc -l)
    echo; echo "### 退避ファイル数: 1 回目=$n1 / 2 回目=$n2(同じなら OK)"
    [ "$n1" = "$n2" ]
    sync=$(~/dotfiles/setup.sh status | tail -1)
    echo "### $sync(分子と分母が同じなら OK)"
    echo "$sync" | grep -Eq "同期: ([0-9]+)/\1$"
    dirty=$(git -C ~/dotfiles status --porcelain)
    echo "### clone の差分: ${dirty:-(なし)}"
    [ -z "$dirty" ]
    echo "### OK"
'
