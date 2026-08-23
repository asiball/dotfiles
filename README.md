# dotfiles

macOS と Linux(Ubuntu / WSL2)共通の設定ファイルと、それを展開するスクリプト。
ロジックは持たず、stow / brew bundle / apt に委譲する薄い HUB。

```
.
├── install.sh          curl 用ブートストラップ(git 確保 → clone → setup.sh)
├── setup.sh            install / status / diff / dump
├── Brewfile            macOS: brew / cask
├── Brewfile.mas        macOS: Mac App Store(既定はスキップ。MAS=1 で有効)
├── apt-packages.txt    Linux: apt で入れる最小セット
└── home/               stow パッケージ。ツリーがそのまま $HOME に symlink される
```

プロジェクト用の eslint / prettier テンプレートは [gist](https://gist.github.com/asiball/ba93a3fa1eec8bfddeeaa09008195b27) に置いている。

## セットアップ

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/asiball/dotfiles/main/install.sh)"
```

`~/dotfiles` に clone(clone 済みなら `git pull --ff-only`)して `setup.sh install all` を実行する。何を導入・変更するかを表示し、確認してから進む。更新も同じコマンドでよい。
手動なら `git -C ~/dotfiles pull && ~/dotfiles/setup.sh install all`(パッケージ + dotfiles)または `install dotfiles`。brew / apt は追加分の導入のみで、既存パッケージの更新はしない。

```bash
./setup.sh status          # 各ファイルが repo を指しているか
./setup.sh diff            # 実環境との差分(stow は dry-run)
./setup.sh dump            # (macOS) 実環境を Brewfile に書き出す
```

## 方針

- OS ごとにファイルを分けず、1 ファイル内で `command -v` / `test -f` で切り替える。
- マシン固有の値は `*.local` に置き、repo に入れない(`~/.gitconfig.local`、`~/.bashrc.local`、`~/.config/fish/conf.d/local.fish`)。
- クリップボードは `clipcopy`(`home/.local/bin/`)に集約する。pbcopy / clip.exe / wl-copy / xclip を自動選択。

## tmux と Claude Code

- tmux の prefix は `Ctrl+S`。キー一覧は `prefix + /`(チートシート)。
- `tmux-claude [dir]` で Claude Code 用のワークスペースを起動(再実行で再接続)。オプションは `tmux-claude -h`。
- Claude Code の hooks がウィンドウ名に状態(作業中 / 入力待ち / 完了)を付ける。
- `home/.claude/` で管理するもの: `keybindings.json`(`Ctrl+S` を無効化。Claude Code に送るときは prefix を 2 回押す)、`statusline.sh`、`hooks/`。
- `~/.claude/settings.json` は環境依存値を含むため repo 管理外。共有したい項目(hooks、statusLine)は `settings.shared.json` に置き、`setup.sh install` が jq で合成する。agent team を tmux ペインに分ける `"teammateMode": "tmux"` は settings.json に直接入れる。
- Windows Terminal から常に tmux で始めるには、Ubuntu プロファイルのコマンドラインを `wsl.exe -d Ubuntu --cd ~ tmux new -A -s main` にする。
