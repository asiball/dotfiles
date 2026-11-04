# dotfiles

macOS と Linux(Ubuntu / WSL2)共通の設定ファイルと、それを展開するスクリプト。
ロジックは持たず、stow / brew bundle / apt に委譲する薄い HUB。Windows は Claude Code の設定だけを `setup.ps1` で同じファイルから展開する。

```
.
├── install.sh          curl 用ブートストラップ(git 確保 → clone → setup.sh)
├── setup.sh            install / list / status / diff / dump
├── setup.ps1           Windows: home/claude/ を ~/.claude に symlink し、設定を合成する(install / status)
├── Brewfile            macOS: brew / cask
├── Brewfile.mas        macOS: Mac App Store(既定はスキップ。MAS=1 で有効)
├── apt-packages.txt    Linux: apt で入れる最小セット
├── vscode/             仕事用 PC に手でコピーする VSCode 設定(展開はしない)
└── home/<名前>/        ツール単位の stow パッケージ(bash, bin, claude, fish, git, tmux, vim, zed, zsh)。
                        各ツリーがそのまま $HOME に symlink される
```

プロジェクト用の eslint / prettier テンプレートは [gist](https://gist.github.com/asiball/ba93a3fa1eec8bfddeeaa09008195b27) に置いている。

## セットアップ

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/asiball/dotfiles/main/install.sh)"
```

`~/dotfiles` に clone(clone 済みなら `git pull --ff-only`)して `setup.sh install all` を実行する。何を導入・変更するかを表示し、確認してから進む。更新も同じコマンドでよい。
手動なら `git -C ~/dotfiles pull && ~/dotfiles/setup.sh install all`(パッケージ + dotfiles)または `install dotfiles`。brew / apt は追加分の導入のみで、既存パッケージの更新はしない。
衝突する既存ファイルは `<元のパス>.backup.<時刻>` に退避し、その都度と最後にまとめて表示する(リンク切れの symlink は削除)。

```bash
./setup.sh list            # 管理している設定の一覧(パッケージごとのファイルと付随処理)
./setup.sh install tmux    # ツール単位で個別に展開(複数可: install tmux bin)
./setup.sh status          # 各ファイルが repo を指しているか
./setup.sh diff            # 実環境との差分(stow は dry-run)
./setup.sh dump            # (macOS) 実環境を Brewfile に書き出す
```

## テスト

```bash
test/run.sh   # Docker のクリーンな Ubuntu で install.sh を 2 回流し、更新と冪等性を確認する(コミット済みの HEAD が対象)
```

## 方針

- OS ごとにファイルを分けず、1 ファイル内で `command -v` / `test -f` で切り替える。
- マシン固有の値は `*.local` に置き、repo に入れない(`~/.gitconfig.local`、`~/.bashrc.local`、`~/.config/fish/conf.d/local.fish`)。
- クリップボードは `clipcopy`(`home/bin/.local/bin/`)に集約する。pbcopy / clip.exe / wl-copy / xclip を自動選択。

## tmux と Claude Code

- tmux の prefix は `Ctrl+S`。キー一覧は `prefix + /`(チートシート)。
- `tmux-claude [dir]` で Claude Code 用のワークスペースを起動(再実行で再接続)。オプションは `tmux-claude -h`。
- Claude Code の hooks がウィンドウ名に状態(作業中 / 入力待ち / 完了)を付ける。
- `home/claude/.claude/` で管理するもの: `keybindings.json`(`Ctrl+S` を無効化。Claude Code に送るときは prefix を 2 回押す)、`statusline.mjs`(Node。ディレクトリ・git・model・effort と、コンテキスト・5h/7d・コストの 2 行)、`hooks/`、`settings.shared*.json`、`merge-settings.mjs`。
- `~/.claude/settings.json` は環境依存値を含むため repo 管理外。共有したい項目(statusLine、model、effort、skillOverrides、plugins など)は `settings.shared.json` に置き、tmux 連携の hooks は `settings.shared.tmux.json` に分ける。`setup.sh install` / `setup.ps1 install` が `merge-settings.mjs`(node)で settings.json に合成する(tmux の分は tmux があるときだけ。同名キーは配列ごと shared 側で置換、shared から消したキーは settings.json に残る。変更する場合は元の settings.json を退避する)。`env` や `permissions`、agent team を tmux ペインに分ける `"teammateMode": "tmux"` のようなマシン固有の項目は settings.json に直接入れる。
- `enabledPlugins` は有効化の状態だけなので、新しいマシンでは `claude plugin marketplace add asiball/claude-kit` と `claude plugin install <名前>@claude-kit` で本体を入れる。
- `statusline.mjs` は環境変数 `STATUSLINE_USAGE_FILE` があれば 5h/7d の使用量をそのファイルにも書く(他のツールが読むため。settings.json の `env` で指定する)。
- Windows: 開発者モード(設定 > システム > 開発者向け)を有効にしてから `pwsh -File setup.ps1 install`。`~/.claude` に symlink を張り、同じ `merge-settings.mjs` で合成する。statusLine と hooks は Git Bash があればそこで実行される。
- Windows Terminal から常に tmux で始めるには、Ubuntu プロファイルのコマンドラインを `wsl.exe -d Ubuntu --cd ~ tmux new -A -s main` にする。

## エディタ

- Zed: `home/zed/`(`~/.config/zed/`。macOS / Linux 共通)。フォントは Brewfile の `font-udev-gothic` / `font-source-han-code-jp`。
  Windows は setup.ps1 の対象外なので、`%APPDATA%\Zed\settings.json` と `AGENTS.md` を clone 内の `home/zed/.config/zed/` への symlink にしている(作成は開発者モードの PowerShell で `New-Item -ItemType SymbolicLink -Path <APPDATA 側> -Target <repo 側>`)。
- VSCode: 私物 PC は Settings Sync で同期する。Settings Sync を使えない仕事用 PC 向けに、エディタ基本の設定だけを `vscode/settings.json` に置いている。手でコピーするだけで、repo へは書き戻さない。
