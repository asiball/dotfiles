# AGENTS.md — このリポジトリ(dotfiles)の制約

macOS / Linux(Ubuntu, WSL2)共通の dotfiles リポジトリ。**シンプルさを最優先**で維持する。
全プロジェクト共通の方針は `~/.claude/CLAUDE.md` 側にあり、ここには本リポジトリ固有の制約だけを書く。

## 役割: HUB(再発明しない)

設定の展開を束ねる薄い HUB。ロジックを自前実装せず、確立されたツールへ委譲する。

- 設定ファイルの symlink 展開 → GNU stow(`home/` が唯一の stow パッケージ)
- パッケージ → macOS は brew bundle、Linux は apt
- Homebrew 本体 → 公式インストーラ
- `install.sh` は curl 用のブートストラップ。git の確保と clone だけを行い、残りは `setup.sh` に渡す。ロジックを二重に持たない

「自分で while ループや差分比較を書きそうになったら、まず委譲先のツールに同じ機能が無いか確認する」。

## シンプルさの制約

- 最低限のコードで目的を満たす。投機的な機能・抽象化・設定可能性を足さない。
- 1 関数 = 1 責務。回避策が必要になったら、まず設計(ファイル分割など)で回避できないか考える。
  - 例: `brew bundle install` に type 別スキップが無い → mas を `Brewfile.mas` に分離し「流さない = スキップ」で解決した。
- 死んだコード・コメントアウトの塊を残さない。
- 変更後に「シニアエンジニアが過剰と言わないか」を自問し、言うなら削る。
- ドキュメントは簡潔に。絵文字は使わない。

## OS 差分の扱い

- OS ごとにファイルを分けない。1 ファイル内で `command -v` / `test -f` の存在チェックで切り替える。
- マシン固有の値(ユーザー名、トークン、ローカルパス)は `*.local` に置き、repo に入れない。
- クリップボード操作は `home/.local/bin/clipcopy` に集約する(pbcopy / clip.exe / wl-copy / xclip)。

## 環境の前提

- クリーンな macOS、または Ubuntu / WSL2 から `./setup.sh install all`(または `install.sh` 経由)だけで動くことを壊さない。
- 外部ツールを増やすのは、一般的・身元が明確・スコープが限定的なものに限る(例: stow、jq)。
- 破壊的な既定動作を作らない(引数なし実行はヘルプ)。`install` は導入・変更内容を表示して確認を取り、既存ファイルを退避してから変更する。
- `setup.sh` は対話入力(`read`)を含むため、`install.sh` の案内は `bash -c "$(curl …)"` 形式にし、`curl | bash` にしない。
- Mac App Store(mas)は既定でスキップ。`MAS=1` のときだけ `Brewfile.mas` を対象に含める。
- 既定シェルの変更は macOS のみ。Linux ではユーザーの選択に任せる。

## セットアップ問題への対応

環境や設定の問題が報告された場合:

1. まず現状を確認する(インストール済みパッケージ・設定・ファイル)。
2. リポジトリの不備が原因ならリポジトリを修正し、再セットアップ時にも再発しないようにする。
3. 修正と同時に現環境にも適用する。
4. push は自動で行わず、ユーザーに確認を取る。

## スコープ

- 管理対象は `home/`(stow)、`Brewfile*`、`apt-packages.txt`、`setup.sh`、`install.sh`。`test/` は Docker でクリーンな Ubuntu の install と 2 回目の冪等性を確認する(`test/run.sh`)。setup.sh / install.sh を変えたら通す。
- Claude Code 関連は `home/.claude/`(keybindings.json、statusline.sh、hooks/)で管理する。`~/.claude/CLAUDE.md` や skills は内容が固まるまで入れない。`~/.claude/settings.json` は環境依存値や機密を含むため管理せず、共有したい項目は `home/.claude/settings.shared.json` に書いて `setup.sh` が jq で合成する。
