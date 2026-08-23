" ####表示設定####
set number       " 行番号の表示
set title        " 編集中のファイル名を表示
set hidden       " 他のファイルが開けるように
set showmatch    " 括弧入力時の対応する括弧の表示
syntax on        " コードの色付け
" set cursorline " カーソルラインをハイライト
" highlight LineNr ctermfg=93 " 行番号の色指定
set backspace=indent,eol,start 
set wildmenu     " コマンドモードの補完
set laststatus=2     " ステータスラインの表示

autocmd ColorScheme * highlight Normal ctermbg=none
autocmd ColorScheme * highlight LineNr ctermbg=none
colorscheme industry " デフォルトの色指定

" 操作設定
" 折り返し時に表示行単位での移動
nnoremap j gj
nnoremap k gk
nnoremap <Down> gj
nnoremap <Up> gk
" showbreak
set showbreak=on
" 入力モードでのカーソル移動
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-h> <Left>
inoremap <C-l> <Right>
set whichwrap=b,s,h,l,<,>,[,],~ " カーソルの左右移動で行末から次の行の行頭への移動が可能になる
" ノーマルモード時にenterで改行
nnoremap <CR> i<CR><Esc>

" ####インデント####
set tabstop=2      " タブ幅
set smartindent    " オートインデント
set expandtab      " タブをスペースに展開
set shiftwidth=2   " インデント幅

" ####検索設定####
set ignorecase     " 大文字/小文字の区別なく検索する
set smartcase      " 検索文字に大文字があれば区別して検索する
set wrapscan       " 検索時に最後まで行ったら最初に戻る
set hlsearch       " 検索語をハイライト表示
set incsearch      " インクリメントサーチの有効化
" ESCキー2度押しでハイライトの切り替え
nnoremap <silent><Esc><Esc> :<C-u>set nohlsearch!<CR>
