vim9script

import autoload 'mplus/text.vim' as text
import autoload 'mplus/link.vim' as link
import autoload 'mplus/todo.vim' as todo
import autoload 'mplus/code.vim' as code
import autoload 'mplus/quote.vim' as quote
import autoload 'mplus/list.vim' as list

# localleader ------------------------------------------------------------{{{1
var leader = get(g:, 'markdown_leader', '<localleader>')

# Text Formatting --------------------------------------------------------{{{1
# Smart toggling for bold, italic, strikethrough, inline code, and remove all styles.
# Supports text objects and visual mode.
var styles = [
    {plug: '<Plug>MarkdownBold',        key: 'b', style: 'markdownBold'},
    {plug: '<Plug>MarkdownItalic',      key: 'i', style: 'markdownItalic'},
    {plug: '<Plug>MarkdownStrike',      key: 's', style: 'markdownStrike'},
    {plug: '<Plug>MarkdownInlineCode',  key: 'c', style: 'markdownCode'},
    {plug: '<Plug>MarkdownRemoveAll',   key: 'd', style: 'markdownRemoveAll'},
]

for item in styles
    # Map to <Plug> if not already mapped
    if !hasmapto(item.plug)
        if empty(mapcheck($'{leader}{item.key}', 'n', 1))
            execute $'nnoremap <buffer> {leader}{item.key} {item.plug}'
        endif
        if empty(mapcheck($'{leader}{item.key}', 'x', 1))
            execute $'xnoremap <buffer> {leader}{item.key} {item.plug}'
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
    {plug: '<Plug>ImageLinkToggle',  key: 'p', link_type: 'image'},
    {plug: '<Plug>FileLinkToggle',  key: 'f', link_type: 'file'},
]

for item in link_items
    # Map to <Plug> if not already mapped
    if !hasmapto(item.plug)
        if empty(mapcheck($'{leader}{item.key}', 'n', 1))
            execute $'nnoremap <buffer> {leader}{item.key} {item.plug}'
        endif
        if empty(mapcheck($'{leader}{item.key}', 'x', 1))
            execute $'xnoremap <buffer> {leader}{item.key} {item.plug}'
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
            execute $'nnoremap <buffer> {leader}{item.key} {item.plug}'
        endif
        if empty(mapcheck($'<leader>{item.key}', 'x', 1))
            execute $'xnoremap <buffer> {leader}{item.key} {item.plug}'
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
var codeblock_item = {plug: '<Plug>MarkdownCodeBlockToggle', key: 'k'}

# 1. Define command interface. -range handles both normal and visual mode ranges.
command! -range ToggleCodeBlock call code.ToggleCodeBlock(<line1>, <line2>)

# 2. Map to <Plug> if not already mapped
if !hasmapto(codeblock_item.plug)
    if empty(mapcheck($'{leader}{codeblock_item.key}', 'n', 1))
        execute $'nnoremap <buffer> {leader}{codeblock_item.key} {codeblock_item.plug}'
    endif
    if empty(mapcheck($'{leader}{codeblock_item.key}', 'x', 1))
        execute $'xnoremap <buffer> {leader}{codeblock_item.key} {codeblock_item.plug}'
    endif
endif

# 3. <Plug> implementation
if empty(maparg(codeblock_item.plug))
    execute $'nnoremap <script> <buffer> {codeblock_item.plug} :ToggleCodeBlock<CR>'
    execute $'xnoremap <script> <buffer> {codeblock_item.plug} :ToggleCodeBlock<CR>'
endif

# Quote Blocks -----------------------------------------------------------{{{1
# Smart toggling for Quote blocks. Supports normal and visual mode.
var quoteblock_item = {plug: '<Plug>MarkdownQuoteBlockToggle', key: 'q'}

# 1. Define command interface. -range handles both normal and visual mode ranges.
command! -range ToggleQuoteBlock call quote.ToggleQuoteBlock(<line1>, <line2>)

# 2. Map to <Plug> if not already mapped
if !hasmapto(quoteblock_item.plug)
    if empty(mapcheck($'{leader}{quoteblock_item.key}', 'n', 1))
        execute $'nnoremap <buffer> {leader}{quoteblock_item.key} {quoteblock_item.plug}'
    endif
    if empty(mapcheck($'{leader}{quoteblock_item.key}', 'x', 1))
        execute $'xnoremap <buffer> {leader}{quoteblock_item.key} {quoteblock_item.plug}'
    endif
endif

# 3. <Plug> implementation
if empty(maparg(quoteblock_item.plug))
    execute $'nnoremap <script> <buffer> {quoteblock_item.plug} :ToggleQuoteBlock<CR>'
    execute $'xnoremap <script> <buffer> {quoteblock_item.plug} :ToggleQuoteBlock<CR>'
endif

# List Formatting --------------------------------------------------------{{{1
# Convert normal lines to list lines; change list symbols for list lines

# Smart toggling for list symbol conversion and formatting.
# Supports normal and visual mode.

# 1. Define command interface. -range handles both normal and visual mode ranges.
command! -range -nargs=1 ListSymbol call list.ChangeSymbol(<q-args>, <line2> - <line1> + 1)

var list_symbol_items = [
    {plug: '<Plug>MarkdownListStar',        key: 'gl*', symbol: '*'},
    {plug: '<Plug>MarkdownListDash',        key: 'gl-', symbol: '-'},
    {plug: '<Plug>MarkdownListPlus',        key: 'gl+', symbol: '+'},
    {plug: '<Plug>MarkdownListNumber',      key: 'gl1', symbol: '1.'},
    {plug: '<Plug>MarkdownListLowerAlpha',  key: 'gla', symbol: 'a.'},
    {plug: '<Plug>MarkdownListUpperAlpha',  key: 'glA', symbol: 'A.'},
    {plug: '<Plug>MarkdownListLowerRome',  key: 'gli', symbol: 'i.'},
    {plug: '<Plug>MarkdownListUpperRome',  key: 'glI', symbol: 'I.'},
    {plug: '<Plug>MarkdownListDelete',      key: 'gld', symbol: 'd'},
]

for item in list_symbol_items
    # 2. Map to <Plug> if not already mapped
    if !hasmapto(item.plug)
        if empty(mapcheck(item.key, 'n', 1))
            execute $'nnoremap <buffer> {item.key} {item.plug}'
        endif
        if empty(mapcheck(item.key, 'x', 1))
            execute $'xnoremap <buffer> {item.key} {item.plug}'
        endif
    endif

    # 3. <Plug> implementation
    if empty(maparg(item.plug))
        execute $'nnoremap <script> <buffer> {item.plug} :ListSymbol {item.symbol}<CR>'
        execute $'xnoremap <script> <buffer> {item.plug} :ListSymbol {item.symbol}<CR>'
    endif
endfor

# Restore original markdown list formatting after gq.
# Supports file or visual selection.
command! -range=% UngqFormat call mplus#gqformat#UngqFormat(<line1>, <line2>)
