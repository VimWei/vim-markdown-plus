set nocompatible
let &runtimepath = simplify(fnamemodify(expand('<sfile>'), ':h') . '/..') . ',' . &runtimepath
set noswapfile
set nomore
set hidden

" 确保 markdown 语法可用
runtime! syntax/markdown.vim

" 添加 wiki.vim 依赖（如果存在）
let s:wiki_path = expand('$HOME/vimfiles/plugged/wiki.vim')
if isdirectory(s:wiki_path)
    let &runtimepath .= ',' . s:wiki_path
    " 由于测试使用 --noplugin，需要显式加载 wiki.vim
    execute 'source ' . s:wiki_path . '/plugin/wiki.vim'
endif

" 添加 vim-quickui 依赖（如果存在）
let s:quickui_path = expand('$HOME/vimfiles/plugged/vim-quickui')
if isdirectory(s:quickui_path)
    let &runtimepath .= ',' . s:quickui_path
    " 由于测试使用 --noplugin，需要显式加载 vim-quickui
    execute 'source ' . s:quickui_path . '/plugin/quickui.vim'
endif
