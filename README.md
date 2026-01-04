# dotfiles 📂

macOS開発環境の設定ファイルとセットアップスクリプトの統合管理リポジトリです。

## 🌟 特徴

- **統合管理**: dotfiles、Homebrew、開発設定を一元管理
- **自動化**: セットアップと同期を自動化するスクリプト
- **安全性**: バックアップ機能とシンボリックリンク管理
- **モジュール型**: 必要な設定のみを選択してインストール可能

## 📁 構成

```
dotfiles/
├── README.md                # このファイル
├── setup_environment.sh     # 統合管理スクリプト
├── brewfiles/              # Homebrew関連
│   ├── Brewfile            # CLI ツール
│   ├── Brewfile_cask       # GUIアプリ
│   └── Masfiles           # Mac App Store アプリ
├── develop/                # 開発設定
│   ├── eslint.config.js    # ESLint設定
│   ├── .prettierrc         # Prettier設定
│   └── .prettierignore     # Prettierの除外設定
└── dotfiles/               # 設定ファイル
    ├── .bashrc             # Bash設定
    ├── .zshrc              # Zsh設定
    ├── .gitconfig          # Git設定
    ├── .vimrc              # Vim設定
    ├── .tmuxrc             # tmux設定
    └── .config/            # 各種アプリ設定
        ├── fish/           # Fish shell設定
        ├── nvim/           # Neovim設定
        ├── gh/             # GitHub CLI設定
        └── htop/           # htop設定
```

## 🚀 クイックスタート

### 新しいマシンでのセットアップ

```bash
# 1. リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. すべてをインストール
./setup_environment.sh install all
```

### 現在の設定をリポジトリに保存

```bash
# 現在のマシンの設定を収集
./setup_environment.sh generate all
```

## 🍺 Homebrewセットアップ

このdotfilesリポジトリを使用する前に、Homebrewのセットアップが必要です。

### Homebrewのインストール

```bash
# Homebrewをインストール（まだインストールしていない場合）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# パスの設定（Apple Silicon Macの場合）
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### mas（Mac App Store CLI）のインストール

Mac App Store アプリの管理にはmasが必要です：

```bash
brew install mas

# App Storeにサインイン
mas signin your@email.com
```

### Homebrew Bundle でパッケージを一括インストール

```bash
# すべてのHomebrewパッケージとアプリをインストール
cd ~/dotfiles/brewfiles
brew bundle --file=Brewfile           # CLI tools
brew bundle --file=Brewfile_cask      # GUI apps
mas install $(cat Masfiles | awk '{print $1}')  # Mac App Store apps

# または統合スクリプトを使用
cd ~/dotfiles
./setup_environment.sh install brew
```

### Homebrewの設定確認

```bash
# Homebrewの動作確認
brew doctor

# インストール済みパッケージの確認
brew list
brew list --cask
mas list
```

## 💡 使用方法

### 基本コマンド

```bash
# ヘルプを表示
./setup_environment.sh

# 全ての設定状態を確認
./setup_environment.sh status

# dotfilesのみインストール
./setup_environment.sh install dotfiles

# Homebrewパッケージのみインストール
./setup_environment.sh install brew

# 開発設定のみインストール
./setup_environment.sh install develop
```

### コマンド詳細

| コマンド | 対象 | 説明 |
|---------|------|------|
| `generate` | `all` \| `dotfiles` \| `brew` \| `develop` | 現在の設定を収集してリポジトリに保存 |
| `install` | `all` \| `dotfiles` \| `brew` \| `develop` | リポジトリから設定をシステムにインストール |
| `status` | - | 現在の同期状態を確認 |

## 🔧 含まれる設定

### シェル設定
- **Bash** (`.bashrc`)
- **Zsh** (`.zshrc`) 
- **Fish** (`.config/fish/`)

### エディタ設定
- **Vim** (`.vimrc`)
- **Neovim** (`.config/nvim/`)

### 開発ツール
- **Git** (`.gitconfig`)
- **GitHub CLI** (`.config/gh/`)
- **ESLint** (`develop/eslint.config.js`)
- **Prettier** (`develop/.prettierrc`)

### ターミナル・システム
- **tmux** (`.tmuxrc`)
- **htop** (`.config/htop/`)

### パッケージ管理
- **Homebrew** (`brewfiles/Brewfile`, `brewfiles/Brewfile_cask`)
- **Mac App Store** (`brewfiles/Masfiles`)

## 📦 Homebrew設定

### CLIツール (Brewfile)
```bash
# 現在インストール済みのCLIツールを更新
brew bundle dump --file=brewfiles/Brewfile --force
```

### GUIアプリ (Brewfile_cask)
```bash
# 現在インストール済みのGUIアプリを更新
brew bundle dump --cask --file=brewfiles/Brewfile_cask --force
```

### Mac App Store (Masfiles)
```bash
# 現在インストール済みのMASアプリを更新
mas list > brewfiles/Masfiles
```

## ⚙️ カスタマイズ

### 新しい設定ファイルの追加

1. `setup_environment.sh`の`manage_dotfiles()`関数を編集
2. `dotfiles`配列に新しいファイル名を追加

```bash
local dotfiles=(
    ".bashrc"
    ".gitconfig"
    ".tmuxrc"
    ".vimrc"
    ".zshrc"
    ".your_new_config"  # 追加
)
```

### 開発設定のカスタマイズ

`develop/`ディレクトリに新しい設定ファイルを追加し、`setup_environment.sh`の`manage_develop()`関数を更新します。

## 🔒 安全性

- **バックアップ**: 既存ファイルは自動的にタイムスタンプ付きでバックアップされます
- **シンボリックリンク**: 設定ファイルはシンボリックリンクで管理されるため、リポジトリと常に同期されます
- **確認機能**: `status`コマンドで現在の同期状態を確認できます

## 🐛 トラブルシューティング

### シンボリックリンクが機能しない場合

```bash
# 手動でバックアップを作成
mv ~/.gitconfig ~/.gitconfig.backup

# 再度インストール
./setup_environment.sh install dotfiles
```

### Homebrew設定が反映されない場合

```bash
# Homebrew Bundleを手動実行
cd brewfiles/
brew bundle --file=Brewfile
brew bundle --file=Brewfile_cask
```

---

**Happy Coding! 🎉**