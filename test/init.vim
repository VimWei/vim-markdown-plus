set nocompatible
let &runtimepath = simplify(fnamemodify(expand('<sfile>'), ':h') . '/..') . ',' . &runtimepath
set noswapfile
set nomore
set hidden

" 确保 markdown 语法可用
runtime! syntax/markdown.vim
