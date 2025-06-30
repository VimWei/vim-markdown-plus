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

# Todo 状态管理，行级别操作
var todo_items = [
  {plug: '<Plug>MarkdownTodoCheckbox',    key: 'tdc', func: 'CheckboxToggle'},
  {plug: '<Plug>MarkdownTodoDone',        key: 'tdd', func: 'DoneToggle'},
  {plug: '<Plug>MarkdownTodoSuspend',     key: 'tds', func: 'SuspendToggle'},
  {plug: '<Plug>MarkdownTodoNext',        key: 'tdn', func: 'MaturityNext'},
  {plug: '<Plug>MarkdownTodoPrevious',    key: 'tdp', func: 'MaturityPrevious'},
]

for item in todo_items
  # 映射到 <Plug>
  if !hasmapto(item.plug)
    if empty(mapcheck($'<leader>{item.key}', 'n', 1))
      execute $'nnoremap <buffer> <leader>{item.key} {item.plug}'
    endif
    if empty(mapcheck($'<leader>{item.key}', 'x', 1))
      execute $'xnoremap <buffer> <leader>{item.key} {item.plug}'
    endif
  endif

  # <Plug> 实现 - 行级别操作
  if empty(maparg(item.plug))
    nnoremap <script> <buffer> {item.plug} <Cmd>call todo.{item.func}(line("."), line("."))<CR>
    xnoremap <script> <buffer> {item.plug} <Cmd>call todo.{item.func}(line("."), line("."))<CR>
  endif
endfor

# 命令接口 - 兼容 vim-quickui 和 vim-navigator 等第三方插件
command! -range TodoCheckboxToggle call todo.CheckboxToggle(<line1>, <line2>)
command! -range TodoDoneToggle call todo.DoneToggle(<line1>, <line2>)
command! -range TodoSuspendToggle call todo.SuspendToggle(<line1>, <line2>)
command! -range TodoMaturityNext call todo.MaturityNext(<line1>, <line2>)
command! -range TodoMaturityPrevious call todo.MaturityPrevious(<line1>, <line2>)

# Text Formatting --------------------------------------------------------{{{1

# 智能加粗/斜体/删除线/行内代码，支持 text-object 操作
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
    execute $'noremap <script> <buffer> {item.plug} <ScriptCmd>&l:opfunc = function(text.ToggleSurround, ["{item.style}"])<cr>g@'
  endif
endfor

# List Formatting --------------------------------------------------------{{{1

# 恢复被 gq 格式化的文档格式
# :UngqFormat：处理整个文件。
# :'<,'>UngqFormat：处理当前选区。
command! -range=% UngqFormat call mplus#gqformat#UngqFormat(<line1>, <line2>)

finish # -----------------------------------------------------------------{{{1

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
