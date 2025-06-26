vim9script
# vim-markdown-plus - Enhanced Markdown editing for Vim
# Author: VimWei
# Description: A complementary plugin that enhances [vim-markdown](https://github.com/tpope/vim-markdown)
#              and [wiki.vim](https://github.com/lervag/wiki.vim) with additional features for
#              comprehensive Markdown editing. Works seamlessly with both plugins to provide
#              advanced text styling, link manipulation, checkbox management, and formatting tools.

if exists('g:loaded_markdown_plus')
  finish
endif
g:loaded_markdown_plus = true

if has('win32') && !has("patch-9.1.1270")
  # Needs Vim version 9.0 and above
  echoerr "[markdown-plus] You need at least Vim 9.1.1270"
  finish
endif

nmap <leader>mm :set ft=markdown<CR>
