" PUBLIC API: Markdown Style Toggles -------------------------------------{{{1
" Bold -------------------------------------------------------------------{{{2
function! mplus#text#ToggleBoldNormal()
    call s:toggle_style_normal('**')
endfunction
function! mplus#text#ToggleBoldVisual() range
    call s:toggle_style_visual('**')
endfunction
function! mplus#text#ToggleBoldOperator(type, ...) range
    call s:toggle_style_operator('**', a:type, a:000)
endfunction

" Italic -----------------------------------------------------------------{{{2
function! mplus#text#ToggleItalicNormal()
    call s:toggle_style_normal('*')
endfunction
function! mplus#text#ToggleItalicVisual() range
    call s:toggle_style_visual('*')
endfunction
function! mplus#text#ToggleItalicOperator(type, ...) range
    call s:toggle_style_operator('*', a:type, a:000)
endfunction

" Strikethrogh -----------------------------------------------------------{{{2
function! mplus#text#ToggleStrikethroughNormal()
    call s:toggle_style_normal('~~')
endfunction
function! mplus#text#ToggleStrikethroughVisual() range
    call s:toggle_style_visual('~~')
endfunction
function! mplus#text#ToggleStrikethroughOperator(type, ...) range
    call s:toggle_style_operator('~~', a:type, a:000)
endfunction

" InlineCode -------------------------------------------------------------{{{2
function! mplus#text#ToggleInlineCodeNormal()
    call s:toggle_style_normal('`')
endfunction
function! mplus#text#ToggleInlineCodeVisual() range
    call s:toggle_style_visual('`')
endfunction
function! mplus#text#ToggleInlineCodeOperator(type, ...) range
    call s:toggle_style_operator('`', a:type, a:000)
endfunction

" INTERNAL IMPLEMENTATION ------------------------------------------------{{{1
function! s:toggle_style_normal(style) " ---------------------------------{{{2
    let lnum = line('.')
    let line_text = getline(lnum)
    let stylelen = len(a:style)
    let curcol = col('.') - 1

    let pos = 0
    while pos < len(line_text)
        let s = match(line_text, a:style, pos)
        if s == -1 | break | endif
        let e = match(line_text, a:style, s + stylelen)
        if e == -1 | break | endif
        let style_start = s
        let style_end = e + stylelen
        " 只要光标在 style 区间内（包括 style 字符本身）
        if curcol >= style_start && curcol < style_end
            let inner_len = style_end - style_start - 2 * stylelen
            if inner_len < 0
                let inner = ''
            else
                let inner = strpart(line_text, style_start + stylelen, inner_len)
            endif
            let new_line = strpart(line_text, 0, style_start) . inner . strpart(line_text, style_end)
            call setline(lnum, new_line)
            call cursor(lnum, style_start + 1)
            return
        endif
        let pos = e + stylelen
    endwhile

    " 如果光标不在任何 style 区间内，才对 <cword> 加 style
    let word = expand('<cword>')
    if word != ''
        let sel_start = -1
        let sel_end = -1
        let pos = 0
        while pos < len(line_text)
            let idx = match(line_text, '\V' . word, pos)
            if idx == -1
                break
            endif
            if curcol >= idx && curcol < idx + len(word)
                let sel_start = idx
                let sel_end = idx + len(word)
                break
            endif
            let pos = idx + 1
        endwhile
        if sel_start >= 0
            let new_line = strpart(line_text, 0, sel_start) . a:style . word . a:style . strpart(line_text, sel_end)
            call setline(lnum, new_line)
            call cursor(lnum, sel_start + stylelen + 1)
        endif
    endif
endfunction

function! s:toggle_style_visual(style) range " ---------------------------{{{2
    let [_, lnum1, col1, _] = getpos("'<")
    let [_, lnum2, col2, _] = getpos("'>")
    if lnum1 == lnum2
        if col1 > col2
            let [col1, col2] = [col2, col1]
        endif
        let line = getline(lnum1)
        let before = strpart(line, 0, col1 - 1)
        let selected = strpart(line, col1 - 1, col2 - col1 + 1)
        let after = strpart(line, col2)
        let stylelen = len(a:style)
        if selected[:stylelen-1] ==# a:style && selected[-stylelen:] ==# a:style
            let new_selected = strpart(selected, stylelen, len(selected) - 2 * stylelen)
        else
            let new_selected = a:style . selected . a:style
        endif
        let new_line = before . new_selected . after
        call setline(lnum1, new_line)
    else
        echo "Multi-line selection is not supported for inline styles."
    endif
endfunction

function! s:toggle_style_operator(style, type, ...) range " --------------{{{2
    if a:type ==# 'line' || a:type ==# 'block'
        let lnum1 = a:firstline
        let lnum2 = a:lastline
        let lines = getline(lnum1, lnum2)
        let text = join(lines, "\n")
        let stylelen = len(a:style)
        if text[:stylelen-1] ==# a:style && text[-stylelen:] ==# a:style
            let text = strpart(text, stylelen, len(text) - 2 * stylelen)
        else
            let text = a:style . text . a:style
        endif
        let new_lines = split(text, "\n")
        call setline(lnum1, new_lines)
    elseif a:type ==# 'char'
        let lnum1 = a:firstline
        let lnum2 = a:lastline
        let col1 = a:1
        let col2 = a:2
        let lines = getline(lnum1, lnum2)
        let first = lines[0]
        let last = lines[-1]
        let before = strpart(first, 0, col1 - 1)
        let after = strpart(last, col2)
        let text = join(lines, "\n")
        let stylelen = len(a:style)
        if text[:stylelen-1] ==# a:style && text[-stylelen:] ==# a:style
            let text = strpart(text, stylelen, len(text) - 2 * stylelen)
        else
            let text = a:style . text . a:style
        endif
        let new_lines = split(before . text . after, "\n")
        call setline(lnum1, new_lines)
    endif
endfunction

" HELPER FUNCTIONS -------------------------------------------------------{{{1
function! s:remove_style_at_cursor(style, lnum, col) abort " -------------{{{2
    let line_text = getline(a:lnum)
    let style_escaped = escape(a:style, '~*_')
    let pattern = style_escaped . '.\{-}' . style_escaped
    let start = 0
    while 1
        let match_pos = matchstrpos(line_text, pattern, start)
        if empty(match_pos[0])
            break
        endif
        let [matched, mstart, mend] = [match_pos[0], match_pos[1], match_pos[2]]
        if a:col-1 >= mstart && a:col-1 < mend
            let text_without_style = strpart(line_text, mstart + len(a:style), mend - mstart - 2 * len(a:style))
            let new_line = strpart(line_text, 0, mstart) . text_without_style . strpart(line_text, mend)
            call setline(a:lnum, new_line)
            call cursor(a:lnum, mstart + 1)
            return 1
        endif
        if mend <= start
            break
        endif
        let start = mend
    endwhile
    return 0
endfunction

function! s:remove_style_if_overlaps(style, lnum1, col1, lnum2, col2) abort " {{{2
    let style_escaped = escape(a:style, '~*_')
    let pattern = style_escaped . '.\{-}' . style_escaped
    let line_text = getline(a:lnum1)
    let start = 0
    while 1
        let match_pos = matchstrpos(line_text, pattern, start)
        if empty(match_pos[0])
            break
        endif
        let [matched, mstart, mend] = [match_pos[0], match_pos[1], match_pos[2]]
        if a:lnum1 == a:lnum2
            if (a:col1-1 <= mend && a:col2-1 >= mstart)
                let text_without_style = strpart(line_text, mstart + len(a:style), mend - mstart - 2 * len(a:style))
                let new_line = strpart(line_text, 0, mstart) . text_without_style . strpart(line_text, mend)
                call setline(a:lnum1, new_line)
                return 1
            endif
        else
            if a:col1-1 <= mstart
                let text_without_style = strpart(line_text, mstart + len(a:style), mend - mstart - 2 * len(a:style))
                let new_line = strpart(line_text, 0, mstart) . text_without_style . strpart(line_text, mend)
                call setline(a:lnum1, new_line)
                return 1
            endif
        endif
        if mend <= start
            break
        endif
        let start = mend
    endwhile
    return 0
endfunction
