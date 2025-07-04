vim9script

g:maplocalleader = "\<space>m"

import autoload 'mplus/code.vim' as code
import autoload 'mplus/todo.vim' as todo
import autoload 'mplus/text.vim' as text
import autoload 'mplus/link.vim' as link

# Code Blocks ------------------------------------------------------------{{{1

command! -range ToggleCodeBlock call code.ToggleCodeBlock(<line1>, <line2>)
vnoremap <leader>cb :ToggleCodeBlock<CR>
nnoremap <leader>cb :ToggleCodeBlock<CR>

# Todo -------------------------------------------------------------------{{{1

# Todo 状态管理，行级别操作
var todo_items = [
    {plug: '<Plug>MarkdownTodoCheckbox',    key: 'tc', func: 'CheckboxToggle'},
    {plug: '<Plug>MarkdownTodoDone',        key: 'td', func: 'DoneToggle'},
    {plug: '<Plug>MarkdownTodoSuspend',     key: 'ts', func: 'SuspendToggle'},
    {plug: '<Plug>MarkdownTodoNext',        key: 'tn', func: 'MaturityNext'},
    {plug: '<Plug>MarkdownTodoPrevious',    key: 'tp', func: 'MaturityPrevious'},
]

# 动态创建命令和映射
for item in todo_items
    # 1. 定义命令接口
    # -range 会自动处理 normal 模式下的计数和 visual 模式下的选区
    # 必须使用完整的 autoload 路径，因为 execute 的上下文无法解析脚本本地的 import 别名
    execute $'command! -range Todo{item.func} call mplus#todo#{item.func}(<line1>, <line2>)'

    # 2. 映射快捷键到 <Plug>
    # 如果用户没有自定义 <Plug> 映射，则创建默认的快捷键
    if !hasmapto(item.plug)
        if empty(mapcheck($'<leader>{item.key}', 'n', 1))
            execute $'nnoremap <buffer> <localleader>{item.key} {item.plug}'
        endif
        if empty(mapcheck($'<leader>{item.key}', 'x', 1))
            execute $'xnoremap <buffer> <localleader>{item.key} {item.plug}'
        endif
    endif

    # 3. <Plug> 的具体实现
    # 如果 <Plug> 没有被任何键映射，则定义其默认行为
    # 此处调用 :Todo{item.func} 命令是正确的，因为命令是在全局定义的
    if empty(maparg(item.plug))
        execute $'nnoremap <script> <buffer> {item.plug} :Todo{item.func}<CR>'
        execute $'xnoremap <script> <buffer> {item.plug} :Todo{item.func}<CR>'
    endif
endfor

# Text Formatting --------------------------------------------------------{{{1

# 智能加粗/斜体/删除线/行内代码，支持 text-object 操作
var styles = [
    {plug: '<Plug>MarkdownBold',    key: 'b', style: 'markdownBold'},
    {plug: '<Plug>MarkdownItalic',  key: 'i', style: 'markdownItalic'},
    {plug: '<Plug>MarkdownStrike',  key: 's', style: 'markdownStrike'},
    {plug: '<Plug>MarkdownCode',    key: 'c', style: 'markdownCode'},
    {plug: '<Plug>MarkdownRemoveAll',  key: 'd', style: 'markdownRemoveAll'},
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

# Link Management --------------------------------------------------------{{{1
var link_items = [
    {plug: '<Plug>WikiLinkToggle',  key: 'l'},
]

for item in link_items
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
        execute $'noremap <script> <buffer> {item.plug} <ScriptCmd>&l:opfunc = function(link.WikiLinkToggle)<cr>g@'
    endif
endfor

# List Formatting --------------------------------------------------------{{{1

# 恢复被 gq 格式化的文档格式
# :UngqFormat：处理整个文件。
# :'<,'>UngqFormat：处理当前选区。
command! -range=% UngqFormat call mplus#gqformat#UngqFormat(<line1>, <line2>)

finish # -----------------------------------------------------------------{{{1

# 为选中的内容添加图片链接，picture
nnoremap <leader>mp viW<ESC>`>a]()<ESC>`<i![<ESC>`>5l
vnoremap <leader>mp <ESC>`>a]()<ESC>`<i![<ESC>`>5l

# 删除光标所在处的链接或图片链接，link picture remove
# 详情查阅 ../../autoload/Markdown.vim
nnoremap <leader>mlr :call Markdown#RemoveLinkAtCursor()<CR>
