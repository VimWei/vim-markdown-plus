vim9script

set nocompatible
&runtimepath = simplify(fnamemodify(expand('<sfile>'), ':h') .. '/..') .. ',' .. &runtimepath
set noswapfile
set nomore
set hidden

runtime! syntax/markdown.vim

var wiki_path = expand('$HOME/vimfiles/plugged/wiki.vim')
if isdirectory(wiki_path)
    &runtimepath ..= ',' .. wiki_path
    execute 'source ' .. wiki_path .. '/plugin/wiki.vim'
endif

var quickui_path = expand('$HOME/vimfiles/plugged/vim-quickui')
if isdirectory(quickui_path)
    &runtimepath ..= ',' .. quickui_path
    execute 'source ' .. quickui_path .. '/plugin/quickui.vim'
endif

def g:RunTestInBuffer(TestFunc: func)
    new
    setlocal filetype=markdown
    runtime! syntax/markdown.vim
    syntax sync fromstart
    redraw
    try
        TestFunc()
    finally
        bwipe!
    endtry
enddef
