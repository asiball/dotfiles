# dotfiles 📂

クリーンな macOS から開発環境を構築するためのセットアップ用リポジトリです。

設定の「再発明」をせず、確立されたツールに**委譲する HUB** として動作します:

- **dotfiles** → [GNU stow](https://www.gnu.org/software/stow/) で symlink 展開
- **Homebrew / cask** → `brew bundle`（`Brewfile`）で一括管理
- **Mac App Store** → `Brewfile.mas` に分離し、**既定はスキップ**（`MAS=1` で有効化、要サインイン）
- **eslint / prettier テンプレート** → `templates/` に静置き（プロジェクトへ手動コピー）

## 📁 構成

```
dotfiles/
├── README.md                # このファイル
├── setup_environment.sh     # 統合管理スクリプト（HUB）
├── brewfiles/
│   ├── Brewfile             # brew / cask
│   └── Brewfile.mas         # Mac App Store アプリ（既定スキップ / MAS=1 で有効）
├── templates/               # プロジェクト用テンプレート（install 対象外）
│   ├── eslint.config.js
│   ├── .prettierrc
│   └── .prettierignore
└── dotfiles/                # stow パッケージ（$HOME へ展開される）
    ├── .bashrc
    ├── .zshrc
    ├── .gitconfig
    ├── .vimrc
    ├── .tmux.conf
    └── .config/
        └── fish/            # Fish shell 設定
```

## 🚀 クイックスタート（クリーンな macOS）

```bash
# 1. リポジトリをクローン
git clone https://github.com/asiball/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. すべてをインストール
./setup_environment.sh install all
```

`install all` は次を自動で行います:

1. **Homebrew が無ければ公式インストーラで導入**し PATH を通す
2. `Brewfile` から brew / cask を一括インストール（`stow` もここで導入）
3. `dotfiles/` を **stow** で `$HOME` に展開（既存ファイルは `*.backup.<timestamp>` へ退避）

fish プラグイン（peco / bobthefish）は fisher で別途インストールが必要です:

```fish
# fish を起動後
fisher install < ~/.config/fish/fish_plugins
```

Mac App Store アプリ（`Brewfile.mas`）は**既定でスキップ**されます。含めるには App Store へサインインしたうえで `MAS=1` を付けて実行します:

```bash
MAS=1 ./setup_environment.sh install all
```

## 💡 使用方法

引数なしで実行するとヘルプを表示します（破壊的な既定動作はありません）。

```bash
./setup_environment.sh                 # ヘルプ
./setup_environment.sh status          # 同期状態を確認
./setup_environment.sh install all     # brew + dotfiles を一括展開
./setup_environment.sh install dotfiles # dotfiles のみ stow で展開
./setup_environment.sh install brew    # Homebrew パッケージのみ
./setup_environment.sh generate        # 現在の環境をリポジトリに収集
./setup_environment.sh diff brew       # Brewfile と実環境の差分
./setup_environment.sh diff dotfiles   # stow の dry-run で展開予定を表示
```

### コマンド詳細

| コマンド   | 対象                      | 説明 |
|-----------|---------------------------|------|
| `generate`| `all` \| `dotfiles` \| `brew` | 現在の設定を収集してリポジトリに保存 |
| `install` | `all` \| `dotfiles` \| `brew` | リポジトリから設定をシステムに展開 |
| `status`  | -                         | 現在の同期状態を確認 |
| `diff`    | `all` \| `dotfiles` \| `brew` | 実環境とリポジトリの差分を表示 |

## 🍺 Homebrew（brew bundle）

brew / cask は `brewfiles/Brewfile`、Mac App Store アプリは `brewfiles/Brewfile.mas` に分離して管理します。
`brew bundle install` には type 別スキップが無いため、**mas を別ファイルにすることで「流さない＝スキップ」**をシンプルに実現しています。

```bash
# 収集（現在の環境を Brewfile に書き出す）
./setup_environment.sh generate brew     # 内部で brew bundle dump --no-mas

# 展開（不足分のみインストール、既存は更新しない）
./setup_environment.sh install brew      # 内部で brew bundle install --no-upgrade

# 差分
./setup_environment.sh diff brew         # brew bundle check / cleanup
```

`MAS=1` を付けると、上記すべてが `Brewfile.mas`（Mac App Store アプリ）も対象に含めます
（収集・インストールには App Store サインインが必要）。

## 🏠 dotfiles（stow）

`dotfiles/` 配下のツリーがそのまま `$HOME` に symlink されます
（`.config/fish/config.fish` → `~/.config/fish/config.fish` のようにネストも展開）。

- 展開前に、衝突する**実体ファイルは自動でバックアップ**されます。
- 既存の symlink は `stow --restow` で張り直されます。
- 新しい dotfile を増やす場合は `dotfiles/` 配下に置くだけで対象になります。

## 🧩 templates（eslint / prettier）

プロジェクト単位の設定なので install 管理はしません。必要なプロジェクトのルートへ手動コピーして使います。

```bash
cp ~/dotfiles/templates/eslint.config.js ~/dotfiles/templates/.prettierrc ~/dotfiles/templates/.prettierignore .
```

## 🔒 安全性

- **バックアップ**: 既存の実体ファイルはタイムスタンプ付きで退避されます。
- **非破壊な既定動作**: 引数なし実行はヘルプ表示のみ。
- **dry-run**: `diff dotfiles` は stow の `--no`（シミュレーション）で確認できます。

---

**Happy Coding! 🎉**
