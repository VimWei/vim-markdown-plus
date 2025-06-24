vim9script

import autoload 'mplus/code.vim' as code
import autoload 'mplus/todo.vim' as todo
import autoload 'mplus/utils.vim' as utils

# Code Blocks ------------------------------------------------------------{{{1

command! -range ToggleCodeBlock call code.ToggleCodeBlock(<line1>, <line2>)
vnoremap <leader>cb :ToggleCodeBlock<CR>
nnoremap <leader>cb :ToggleCodeBlock<CR>

# Todo -------------------------------------------------------------------{{{1

command! -range TodoCheckboxToggle call todo.CheckboxToggle(<line1>, <line2>)
vnoremap <leader>tdc :TodoCheckboxToggle<CR>
nnoremap <leader>tdc :TodoCheckboxToggle<CR>

command! -range TodoDoneToggle call todo.DoneToggle(<line1>, <line2>)
vnoremap <leader>tdd :TodoDoneToggle<CR>
nnoremap <leader>tdd :TodoDoneToggle<CR>

command! -range TodoSuspendToggle call todo.SuspendToggle(<line1>, <line2>)
vnoremap <leader>tds :TodoSuspendToggle<CR>
nnoremap <leader>tds :TodoSuspendToggle<CR>

command! -range TodoMaturityNext call todo.MaturityNext(<line1>, <line2>)
vnoremap <leader>tdn :TodoMaturityNext<CR>
nnoremap <leader>tdn :TodoMaturityNext<CR>

command! -range TodoMaturityPrevious call todo.MaturityPrevious(<line1>, <line2>)
vnoremap <leader>tdp :TodoMaturityPrevious<CR>
nnoremap <leader>tdp :TodoMaturityPrevious<CR>

finish

# Text Formatting --------------------------------------------------------{{{1

# 智能加粗/斜体/删除线/行内代码，支持 text-object 操作
for [key, func] in [['b', 'Bold'], ['i', 'Italic'], ['s', 'Strikethrough'], ['c', 'InlineCode']]
  nmap <buffer> <silent> "<leader>m{key}" mplus.text["Toggle{func}Normal"]
  xmap <buffer> <silent> "<leader>m{key}" {-> mplus.text["Toggle{func}Visual"]()}
  nmap <buffer> <silent> "<leader>o{key}" $":let &opfunc = mplus.text['Toggle{func}Operator'] | normal! g@"
endfor

# Link Management --------------------------------------------------------{{{1

# Link/Image Toggling (intelligent switch)
# <leader>mll: Toggle a regular [link]() - create if none, remove if exists
# Normal mode - use as operator
nnoremap <silent> <leader>mll :set opfunc=mplus#link#ToggleLinkAtCursor<CR>g@
# Visual mode - apply to selection
xnoremap <silent> <leader>mll :<C-u>call mplus#link#ToggleLinkAtCursor()<CR>
# Operator-pending mode - apply to motion
onoremap <silent> <leader>mll :normal v<CR>

# <leader>mpp: Toggle an ![image link]() - create if none, remove if exists
# Normal mode - use as operator
nnoremap <silent> <leader>mpp :set opfunc=mplus#link#ToggleImageLinkAtCursor<CR>g@
# Visual mode - apply to selection
xnoremap <silent> <leader>mpp :<C-u>call mplus#link#ToggleImageLinkAtCursor()<CR>
# Operator-pending mode - apply to motion
onoremap <silent> <leader>mpp :normal v<CR>

# Link manipulation
# "u"nwrap link, keep URL as text
nnoremap <leader>mlu :call mplus#link#RemoveLinkButKeepUrl()<CR>

# List Formatting --------------------------------------------------------{{{1

# 自动将新建空 buffer 设置为 markdown，从而可以对 list 使用 gqip 格式化命令
augroup MarkdownPlusNewBufferFiletype
  autocmd!
  autocmd BufEnter * mplus#CheckAndSetFiletype()
augroup END

# UngqFormat: 恢复被 gq 格式化的文档格式
command! -range=% UngqFormat mplus#list#UngqFormat(<line1>, <line2>)
