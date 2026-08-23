# dotfiles

macOS と Linux(Ubuntu / WSL2)で共通に使う設定ファイルと、それを展開するスクリプト。
ロジックは自前で持たず、確立されたツールに委譲する薄い HUB として動く。

| 役割 | 委譲先 |
|---|---|
| 設定ファイルの展開(symlink) | GNU stow(`home/` をそのまま `$HOME` へ) |
| パッケージ導入(macOS) | `brew bundle`(`Brewfile`、`Brewfile.mas`) |
| パッケージ導入(Linux) | `apt`(`apt-packages.txt`) |

## 構成

```
.
├── setup.sh            エントリポイント(install / status / diff / dump)
├── Brewfile            macOS: brew / cask
├── Brewfile.mas        macOS: Mac App Store(既定はスキップ。MAS=1 で有効)
├── apt-packages.txt    Linux: apt で入れる最小セット
├── home/               stow パッケージ。ツリーがそのまま $HOME に symlink される
│   ├── .bashrc  .zshrc  .vimrc  .gitconfig
│   ├── .config/fish/        config.fish, fish_plugins, completions/
│   ├── .config/tmux/        tmux.conf, cheatsheet.md
│   ├── .claude/             keybindings.json(Claude Code)
│   └── .local/bin/          clipcopy, tmux-claude
└── templates/          プロジェクト用テンプレート(eslint / prettier。手動コピー)
```

## セットアップ

```bash
git clone https://github.com/asiball/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh install all        # パッケージ + dotfiles
./setup.sh install dotfiles   # dotfiles のみ
```

`install` は次を行う。

1. パッケージ導入: macOS は Homebrew(無ければ導入)+ `brew bundle`、Linux は `apt-get install`
2. `home/` を stow で `$HOME` に展開。衝突する実体ファイルは `*.backup.<timestamp>` に退避
3. `~/.gitconfig.local` が無ければ git の user 情報を聞いて作成
4. fish があれば fisher とプラグインを導入。macOS では既定シェルを fish に変更(Linux は手動で `chsh`)

WSL2 の前提: Windows 側に `clip.exe` があること(標準で入っている)。

### その他のコマンド

```bash
./setup.sh status          # 各ファイルが repo を指しているか
./setup.sh diff dotfiles   # stow の dry-run
./setup.sh diff packages   # Brewfile / apt-packages.txt と実環境の差分
./setup.sh dump            # (macOS) 実環境を Brewfile に書き出す
MAS=1 ./setup.sh install   # Mac App Store アプリも含める(要サインイン)
```

## OS 差分の扱い

- 設定ファイルは分けず、1 ファイル内で存在チェック(`command -v` / `test -f`)によって切り替える。
- マシン固有の値は `*.local` に置き、repo には入れない。
  - `~/.gitconfig.local`: git の user、credential helper、`core.sshCommand` など
  - `~/.bashrc.local`: nvm、マシン固有の PATH / alias
  - `~/.config/fish/conf.d/local.fish`: fish のマシン固有設定
- クリップボードは `clipcopy`(`home/.local/bin/`)に集約する。pbcopy / clip.exe(WSL2) / wl-copy / xclip を自動選択する。

## tmux と Claude Code

`~/.config/tmux/tmux.conf` は macOS / WSL2 共通。prefix は `Ctrl+S`。

- `tmux-claude [-l 2|4] [dir]`: Claude Code 用のワークスペースを起動する。既にあれば再接続する。
  - `-l 2`(既定): 左 claude、右シェル
  - `-l 4`: 2x2(左上 claude、他 3 つはシェル)
  - どちらも別ウィンドウ `shell` を作る
- `tmux-claude -c` は `claude --continue` で前回の会話を再開、`-- <引数>` は claude にそのまま渡す(`-- -w feature-x` で worktree、`-- --resume 名前`)。`-L` で一覧、`-k [dir]` で終了。
- `prefix + /` でチートシート、`prefix + ?` で全キー一覧。
- 状態の可視化
  - Claude Code の hooks が `~/.claude/hooks/tmux-claude-status` を呼び、ウィンドウ名に 🤖 作業中 / 💬 入力待ち / ✅ 完了 を付ける。ペインが 2 つ以上のときはペイン枠にも番号・実行中コマンド・状態を出す。
  - hooks の配線(`hooks/tmux-claude-status.hooks.json`)は `setup.sh install dotfiles` が `~/.claude/settings.json` に合成する(jq が必要)。`preferredNotifChannel: terminal_bell` も同時に入り、ベルが鳴ったウィンドウは tmux が強調する。
- Claude Code 側の設定
  - `~/.claude/keybindings.json`(stow で展開): `Ctrl+S`(stash)を無効化し tmux の prefix と衝突しないようにする。Claude Code に `Ctrl+S` を送るときは prefix を 2 回押す。
  - `~/.claude/settings.json` に `"teammateMode": "tmux"` を入れると agent team の teammate が tmux ペインに分かれる(settings.json は機密や環境依存値を含むため repo 管理外)。teammate は現在のウィンドウを分割するので、team を使うときは 2 ペインレイアウトが収まりがよい。
  - Shift+Enter 改行は tmux.conf の `extended-keys` / `allow-passthrough` 設定で通る。
- Windows Terminal から常に tmux の中で始めるには、Ubuntu プロファイルの「コマンド ライン」を次にする(開いた時点で `main` セッションに接続、以後 `tmux-claude` はその中から切り替わる):

  ```
  wsl.exe -d Ubuntu --cd ~ tmux new -A -s main
  ```

  WSL2 では `stow` 実行時に `BUG in find_stowed_path? Absolute/relative mismatch ...` と出ることがあるが、`$HOME` 直下にある無関係な絶対パス symlink に対する stow 2.3.1 の警告で、展開結果には影響しない。

## templates

プロジェクト単位の設定なので install 対象外。必要なプロジェクトへ手動コピーする。

```bash
cp ~/dotfiles/templates/{eslint.config.js,.prettierrc,.prettierignore} .
```
