# TODO

## fish 補完を追加する

`setup_environment.sh` の fish シェル補完を用意する（理想機能）。

- 配置: `dotfiles/.config/fish/completions/setup_environment.fish`
  - dotfiles 配下に置けば `install dotfiles`（stow）でそのまま `~/.config/fish/completions/` に展開される。
- 補完対象:
  - 第1引数（サブコマンド）: `generate` / `install` / `status` / `diff` / `help`
  - 第2引数（対象）: `all` / `dotfiles` / `brew`
- 本体は bash のまま。補完ファイルを追加するだけでよい（言語の書き換え不要）。

> メモ: `gh` 未導入のため GitHub issue 化は保留。導入後に本項目を issue へ転記する。
