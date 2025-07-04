vim9script

g:maplocalleader = "\<space>m"

import autoload 'mplus/code.vim' as code
import autoload 'mplus/todo.vim' as todo
import autoload 'mplus/text.vim' as text
import autoload 'mplus/link.vim' as link

# Text Formatting --------------------------------------------------------{{{1
# Smart toggling for bold, italic, strikethrough, inline code, and remove all styles.
# Supports text objects and visual mode.
var styles = [
    {plug: '<Plug>MarkdownBold',    key: 'b', style: 'markdownBold'},
    {plug: '<Plug>MarkdownItalic',  key: 'i', style: 'markdownItalic'},
    {plug: '<Plug>MarkdownStrike',  key: 's', style: 'markdownStrike'},
    {plug: '<Plug>MarkdownCode',    key: 'c', style: 'markdownCode'},
    {plug: '<Plug>MarkdownRemoveAll',  key: 'd', style: 'markdownRemoveAll'},
]

for item in styles
    # Map to <Plug> if not already mapped
    if !hasmapto(item.plug)
        if empty(mapcheck($'<localleader>{item.key}', 'n', 1))
            execute $'nnoremap <buffer> <localleader>{item.key} {item.plug}'
        endif
        if empty(mapcheck($'<localleader>{item.key}', 'x', 1))
            execute $'xnoremap <buffer> <localleader>{item.key} {item.plug}'
        endif
    endif

    # <Plug> implementation
    if empty(maparg(item.plug))
        execute $'noremap <script> <buffer> {item.plug} <ScriptCmd>&l:opfunc = function(text.ToggleSurround, ["{item.style}"])<cr>g@'
    endif
endfor

# Link Management --------------------------------------------------------{{{1
# Smart toggling for wiki links and image links.
# Supports text objects and visual mode.
var link_items = [
    {plug: '<Plug>WikiLinkToggle',  key: 'l', link_type: 'wiki'},
    {plug: '<Plug>MarkdownImgLinkToggle',  key: 'p', link_type: 'image'},
]

for item in link_items
    # Map to <Plug> if not already mapped
    if !hasmapto(item.plug)
        if empty(mapcheck($'<localleader>{item.key}', 'n', 1))
            execute $'nnoremap <buffer> <localleader>{item.key} {item.plug}'
        endif
        if empty(mapcheck($'<localleader>{item.key}', 'x', 1))
            execute $'xnoremap <buffer> <localleader>{item.key} {item.plug}'
        endif
    endif

    # <Plug> implementation
    if empty(maparg(item.plug))
        execute $'noremap <script> <buffer> {item.plug} <ScriptCmd>&l:opfunc = function(link.ToggleLink, ["{item.link_type}"])<cr>g@'
    endif
endfor

# Todo -------------------------------------------------------------------{{{1
# Smart toggling for todo status (checkbox, done, suspend, maturity).
# Generates commands and mappings dynamically.
var todo_items = [
    {plug: '<Plug>MarkdownTodoCheckbox',    key: 'tc', func: 'CheckboxToggle'},
    {plug: '<Plug>MarkdownTodoDone',        key: 'td', func: 'DoneToggle'},
    {plug: '<Plug>MarkdownTodoSuspend',     key: 'ts', func: 'SuspendToggle'},
    {plug: '<Plug>MarkdownTodoNext',        key: 'tn', func: 'MaturityNext'},
    {plug: '<Plug>MarkdownTodoPrevious',    key: 'tp', func: 'MaturityPrevious'},
]

for item in todo_items
    # 1. Define command interface. -range handles both normal and visual mode ranges.
    # Use full autoload path for execute context.
    execute $'command! -range Todo{item.func} call mplus#todo#{item.func}(<line1>, <line2>)'

    # 2. Map to <Plug> if not already mapped
    if !hasmapto(item.plug)
        if empty(mapcheck($'<leader>{item.key}', 'n', 1))
            execute $'nnoremap <buffer> <localleader>{item.key} {item.plug}'
        endif
        if empty(mapcheck($'<leader>{item.key}', 'x', 1))
            execute $'xnoremap <buffer> <localleader>{item.key} {item.plug}'
        endif
    endif

    # 3. <Plug> implementation
    if empty(maparg(item.plug))
        execute $'nnoremap <script> <buffer> {item.plug} :Todo{item.func}<CR>'
        execute $'xnoremap <script> <buffer> {item.plug} :Todo{item.func}<CR>'
    endif
endfor

# Code Blocks ------------------------------------------------------------{{{1
# Smart toggling for fenced code blocks. Supports normal and visual mode.
var codeblock_item = {plug: '<Plug>MarkdownCodeBlockToggle', key: 'cb'}

# 1. Define command interface. -range handles both normal and visual mode ranges.
command! -range ToggleCodeBlock call code.ToggleCodeBlock(<line1>, <line2>)

# 2. Map to <Plug> if not already mapped
if !hasmapto(codeblock_item.plug)
    if empty(mapcheck($'<localleader>{codeblock_item.key}', 'n', 1))
        execute $'nnoremap <buffer> <localleader>{codeblock_item.key} {codeblock_item.plug}'
    endif
    if empty(mapcheck($'<localleader>{codeblock_item.key}', 'x', 1))
        execute $'xnoremap <buffer> <localleader>{codeblock_item.key} {codeblock_item.plug}'
    endif
endif

# 3. <Plug> implementation
if empty(maparg(codeblock_item.plug))
    execute $'nnoremap <script> <buffer> {codeblock_item.plug} :ToggleCodeBlock<CR>'
    execute $'xnoremap <script> <buffer> {codeblock_item.plug} :ToggleCodeBlock<CR>'
endif

# List Formatting --------------------------------------------------------{{{1
# Restore original markdown list formatting after gq.
# Supports file or visual selection.
command! -range=% UngqFormat call mplus#gqformat#UngqFormat(<line1>, <line2>)
