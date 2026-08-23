# tmux チートシート   (prefix = Ctrl+S。prefix を押してから次のキー)

## まずこれだけ(覚えるのは 5 つ)
  prefix |      左右に分割          prefix -      上下に分割
  prefix hjkl   ペイン移動(マウスクリックでも可)
  prefix z      ペイン最大化 ⇄ 戻す
  prefix d      デタッチ(作業は残る)。戻るときは  tmux a
  prefix /      このチートシート     prefix ?      全キー一覧

## ペイン
  prefix HJKL   リサイズ(連打可。境界ドラッグでも可)
  prefix x      ペインを閉じる(確認あり)
  prefix q      ペイン番号を表示 → 番号キーで移動
  prefix {  }   ペインの入れ替え
  prefix e      全ペインに同時入力 on/off

## ウィンドウ(タブ)
  prefix c      新規ウィンドウ       prefix ,      名前変更
  prefix n / p  次 / 前              prefix 1-9    番号で移動
  prefix w      一覧から選ぶ         prefix &      ウィンドウを閉じる

## セッション
  tmux-claude [dir]        Claude Code 用ワークスペース(左 claude / 右シェル)を起動/再接続
  tmux-claude -l 4 [dir]   2x2 レイアウト(左上 claude、他はシェル)
  tmux ls             一覧           tmux a -t 名前   接続
  prefix s            セッション切替  prefix $         名前変更

## コピー
  prefix [      コピーモード(vi)。v で選択開始、y でクリップボードへ、q で抜ける
  マウスでドラッグ選択 → 離した時点でクリップボードへ
  (Claude Code のペイン内はアプリがマウスを扱う。Ctrl+Shift+C でコピー)

## Claude Code
  Ctrl+S は tmux が取る。Claude Code に Ctrl+S を送るときは prefix prefix(2 回押し)
  Shift+Enter 改行は tmux.conf の extended-keys 設定で通る
  agent team の teammate は tmux のペインとして自動で増える(settings.json: teammateMode=tmux)

## 設定
  prefix r      ~/.config/tmux/tmux.conf を再読み込み
