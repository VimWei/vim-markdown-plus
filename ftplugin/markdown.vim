vim9script

import autoload 'mplus/code.vim' as code
import autoload 'mplus/checkbox.vim' as checkbox
# import autoload 'mplus/utils.vim' as utils

# Code Blocks ------------------------------------------------------------{{{1

## Smart Toggle Wrap selected lines in code block
command! -range ToggleCodeBlock call code.ToggleCodeBlock(<line1>, <line2>)
vnoremap <leader>mcb :ToggleCodeBlock<CR>
nnoremap <leader>mcb :ToggleCodeBlock<CR>

# Checkboxes -------------------------------------------------------------{{{1

# Toggle Todo checkbox
command! -range ToggleTodoCheckbox call checkbox.ToggleTodoCheckbox(<line1>, <line2>)
vnoremap <leader>mtd :ToggleTodoCheckbox<CR>
nnoremap <leader>mtd :ToggleTodoCheckbox<CR>

# 独立 checkbox 状态切换命令与映射
command! -range ToggleDoneStatus call checkbox.ToggleDoneStatus(<line1>, <line2>)
vnoremap <leader>mdd :ToggleDoneStatus<CR>
nnoremap <leader>mdd :ToggleDoneStatus<CR>

command! -range ToggleRejectedStatus call checkbox.ToggleRejectedStatus(<line1>, <line2>)
vnoremap <leader>mdr :ToggleRejectedStatus<CR>
nnoremap <leader>mdr :ToggleRejectedStatus<CR>

command! -range IncreaseDoneStatus call checkbox.IncreaseDoneStatus(<line1>, <line2>)
vnoremap <leader>mdn :IncreaseDoneStatus<CR>
nnoremap <leader>mdn :IncreaseDoneStatus<CR>

command! -range DecreaseDoneStatus call checkbox.DecreaseDoneStatus(<line1>, <line2>)
vnoremap <leader>mdp :DecreaseDoneStatus<CR>
nnoremap <leader>mdp :DecreaseDoneStatus<CR>

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
