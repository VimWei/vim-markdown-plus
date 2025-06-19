" vim-markdown-plus - Enhanced Markdown editing for Vim
" Author: VimWei
" Description: Adds extra features to [vim-markdown](https://github.com/tpope/vim-markdown)

if exists('g:loaded_markdown_plus')
  finish
endif
let g:loaded_markdown_plus = 1

" Load documentation
if exists(':helptags')
  runtime! doc/markdown_plus.txt
endif

" (后续功能将在此文件中实现或调用 autoload/markdown_plus/ 下的函数) 