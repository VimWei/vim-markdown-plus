" vim-markdown-plus - Enhanced Markdown editing for Vim
" Author: VimWei
" Description: A complementary plugin that enhances [vim-markdown](https://github.com/tpope/vim-markdown)
"              and [wiki.vim](https://github.com/lervag/wiki.vim) with additional features for
"              comprehensive Markdown editing. Works seamlessly with both plugins to provide
"              advanced text styling, link manipulation, checkbox management, and formatting tools.

" Load -------------------------------------------------------------------{{{1

if exists('g:loaded_markdown_plus')
  finish
endif
let g:loaded_markdown_plus = 1

" Load documentation
if exists(':helptags')
  runtime! doc/markdown_plus.txt
endif

" Text Formatting --------------------------------------------------------{{{1

" 智能加粗/斜体/删除线/行内代码，支持 text-object 操作
for [key, func] in [['b', 'ToggleBold'], ['i', 'ToggleItalic'], ['s', 'ToggleStrikethrough'], ['c', 'ToggleInlineCode']]
  " Normal mode - use as operator
  execute 'nnoremap <silent> <leader>m'.key.' :set opfunc=markdown_plus#text#'.func.'<CR>g@'
  " Visual mode - apply to selection
  execute 'xnoremap <silent> <leader>m'.key.' :<C-u>call markdown_plus#text#'.func.'()<CR>'
  " Operator-pending mode - apply to motion
  execute 'onoremap <silent> <leader>m'.key.' :normal v<CR>'
endfor

" Code Blocks ------------------------------------------------------------{{{1

" Wrap selected lines in code block
command! -range WrapInCodeBlock <line1>,<line2>call markdown_plus#code#WrapInCodeBlock()
vnoremap <leader>mcb :WrapInCodeBlock<CR>
nnoremap <leader>mcb :WrapInCodeBlock<CR>

" Checkboxes -------------------------------------------------------------{{{1

" Toggle Todo checkbox
command! -range ToggleTodoCheckbox <line1>,<line2>call markdown_plus#checkbox#ToggleTodoCheckbox()
vnoremap <leader>mtd :ToggleTodoCheckbox<CR>
nnoremap <leader>mtd :ToggleTodoCheckbox<CR>

" 独立 checkbox 状态切换命令与映射
command! -range ToggleDoneStatus <line1>,<line2>call markdown_plus#checkbox#ToggleDoneStatus()
vnoremap <leader>mdd :ToggleDoneStatus<CR>
nnoremap <leader>mdd :ToggleDoneStatus<CR>

command! -range ToggleRejectedStatus <line1>,<line2>call markdown_plus#checkbox#ToggleRejectedStatus()
vnoremap <leader>mdr :ToggleRejectedStatus<CR>
nnoremap <leader>mdr :ToggleRejectedStatus<CR>

command! -range IncreaseDoneStatus <line1>,<line2>call markdown_plus#checkbox#IncreaseDoneStatus()
vnoremap <leader>mdi :IncreaseDoneStatus<CR>
nnoremap <leader>mdi :IncreaseDoneStatus<CR>

command! -range DecreaseDoneStatus <line1>,<line2>call markdown_plus#checkbox#DecreaseDoneStatus()
vnoremap <leader>mdp :DecreaseDoneStatus<CR>

" Link Management --------------------------------------------------------{{{1

" Link/Image Toggling (intelligent switch)
" <leader>mll: Toggle a regular [link]() - create if none, remove if exists
" Normal mode - use as operator
nnoremap <silent> <leader>mll :set opfunc=markdown_plus#link#ToggleLinkAtCursor<CR>g@
" Visual mode - apply to selection
xnoremap <silent> <leader>mll :<C-u>call markdown_plus#link#ToggleLinkAtCursor()<CR>
" Operator-pending mode - apply to motion
onoremap <silent> <leader>mll :normal v<CR>

" <leader>mpp: Toggle an ![image link]() - create if none, remove if exists
" Normal mode - use as operator
nnoremap <silent> <leader>mpp :set opfunc=markdown_plus#link#ToggleImageLinkAtCursor<CR>g@
" Visual mode - apply to selection
xnoremap <silent> <leader>mpp :<C-u>call markdown_plus#link#ToggleImageLinkAtCursor()<CR>
" Operator-pending mode - apply to motion
onoremap <silent> <leader>mpp :normal v<CR>

" Link manipulation
" "u"nwrap link, keep URL as text
nnoremap <leader>mlu :call markdown_plus#link#RemoveLinkButKeepUrl()<CR>

" List Formatting --------------------------------------------------------{{{1

" 自动将新建空 buffer 设置为 markdown，从而可以对 list 使用 gqip 格式化命令
augroup MarkdownPlusNewBufferFiletype
  autocmd!
  autocmd BufEnter * call markdown_plus#CheckAndSetFiletype()
augroup END

" UngqFormat: 恢复被 gq 格式化的文档格式
command! -range=% UngqFormat call markdown_plus#list#UngqFormat(<line1>, <line2>)
