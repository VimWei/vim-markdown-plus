vim9script

g:maplocalleader = "\<space>m"

import autoload 'mplus/code.vim' as code
import autoload 'mplus/todo.vim' as todo
import autoload 'mplus/text.vim' as text

# Code Blocks ------------------------------------------------------------{{{1

command! -range ToggleCodeBlock call code.ToggleCodeBlock(<line1>, <line2>)
vnoremap <leader>cb :ToggleCodeBlock<CR>
nnoremap <leader>cb :ToggleCodeBlock<CR>

# Todo -------------------------------------------------------------------{{{1

var todo_cmds = [
  {name: 'TodoCheckboxToggle', func: 'CheckboxToggle', key: 'tdc'},
  {name: 'TodoDoneToggle', func: 'DoneToggle', key: 'tdd'},
  {name: 'TodoSuspendToggle', func: 'SuspendToggle', key: 'tds'},
  {name: 'TodoMaturityNext', func: 'MaturityNext', key: 'tdn'},
  {name: 'TodoMaturityPrevious', func: 'MaturityPrevious', key: 'tdp'},
]

for item in todo_cmds
  execute $'command! -range {item.name} call todo.{item.func}(<line1>, <line2>)'
  execute $'vnoremap <leader>{item.key} :{item.name}<CR>'
  execute $'nnoremap <leader>{item.key} :{item.name}<CR>'
endfor

# Text Formatting --------------------------------------------------------{{{1

# 智能加粗/斜体/删除线/行内代码，支持 text-object 操作
def SetSurroundOpFunc(style: string)
  &l:opfunc = function(text.ToggleSurround, [style])
enddef

var styles = [
  {plug: '<Plug>MarkdownBold',    key: 'b', style: 'markdownBold'},
  {plug: '<Plug>MarkdownItalic',  key: 'i', style: 'markdownItalic'},
  {plug: '<Plug>MarkdownStrike',  key: 's', style: 'markdownStrike'},
  {plug: '<Plug>MarkdownCode',    key: 'c', style: 'markdownCode'},
]

for item in styles
  # 映射到 <Plug>
  if !hasmapto(item.plug)
    if empty(mapcheck($'<localleader>{item.key}', 'n', 1))
      execute $'nnoremap <buffer> <localleader>{item.key} {item.plug}'
    endif
    if empty(mapcheck($'<localleader>{item.key}', 'x', 1))
      execute $'xnoremap <buffer> <localleader>{item.key} {item.plug}'
    endif
  endif

  # <Plug> 实现
  if empty(maparg(item.plug))
    execute $'noremap <script> <buffer> {item.plug} <ScriptCmd>SetSurroundOpFunc("{item.style}")<cr>g@'
  endif
endfor

finish

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

# UngqFormat: 恢复被 gq 格式化的文档格式
command! -range=% UngqFormat mplus#gqformat#UngqFormat(<line1>, <line2>)
