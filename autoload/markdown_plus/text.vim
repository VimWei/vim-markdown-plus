function! markdown_plus#text#ToggleInlineCode() range
    if mode() ==# 'v' || mode() ==# 'V' || mode() ==# '\<C-v>'
        normal! `<v`>y
        let sel = getreg('"')
        let lnum1 = line("'<")
        let col1 = col("'<")
        let lnum2 = line("'>")
        let col2 = col("'>")
        let lines = getline(lnum1, lnum2)
        let first = lines[0]
        let last = lines[-1]
        let before = strpart(first, 0, col1 - 1)
        let after = strpart(last, col2)
        let text = join(lines, "\n")
        let code_removed = s:remove_inline_code_if_overlaps(lnum1, col1, lnum2, col2)
        if !code_removed
            let text = '`' . text . '`'
            let new_lines = split(before . text . after, "\n")
            call setline(lnum1, new_lines)
        endif
    else
        let lnum = line('.')
        let col = col('.')
        let line_text = getline(lnum)
        let code_removed = s:remove_inline_code_at_cursor(lnum, col)
        if !code_removed
            let word = expand('<cword>')
            let start = match(line_text, '\k*', col - 1)
            let end = start + len(word)
            if word =~? '^`.*`$'
                let new_word = substitute(word, '^`', '', '')
                let new_word = substitute(new_word, '`$', '', '')
            else
                let new_word = '`' . word . '`'
            endif
            let new_line = strpart(line_text, 0, start) . new_word . strpart(line_text, end)
            call setline(lnum, new_line)
            call cursor(lnum, start + 1)
        endif
    endif
endfunction

function! markdown_plus#text#ToggleBold() range
    let style = get(g:, 'markdown_plus_bold_style', '**')
    call s:toggle_style(style)
endfunction

function! markdown_plus#text#ToggleItalic() range
    let style = get(g:, 'markdown_plus_italic_style', '*')
    call s:toggle_style(style)
endfunction

function! markdown_plus#text#ToggleStrikethrough() range
    let style = '~~'
    call s:toggle_style(style)
endfunction

function! s:toggle_style(style) range
    if mode() ==# 'v' || mode() ==# 'V' || mode() ==# '\<C-v>'
        normal! `<v`>y
        let sel = getreg('"')
        let lnum1 = line("'<")
        let col1 = col("'<")
        let lnum2 = line("'>")
        let col2 = col("'>")
        let lines = getline(lnum1, lnum2)
        let first = lines[0]
        let last = lines[-1]
        let before = strpart(first, 0, col1 - 1)
        let after = strpart(last, col2)
        let text = join(lines, "\n")
        let style_removed = s:remove_style_if_overlaps(a:style, lnum1, col1, lnum2, col2)
        if !style_removed
            let text = a:style . text . a:style
            let new_lines = split(before . text . after, "\n")
            call setline(lnum1, new_lines)
        endif
    else
        let lnum = line('.')
        let col = col('.')
        let line_text = getline(lnum)
        let style_removed = s:remove_style_at_cursor(a:style, lnum, col)
        if !style_removed
            let word = expand('<cword>')
            let start = match(line_text, '\k*', col - 1)
            let end = start + len(word)
            let pat = '^' . escape(a:style, '*_') . '.*' . escape(a:style, '*_') . '$'
            if word =~? pat
                let new_word = substitute(word, '^' . escape(a:style, '*_'), '', '')
                let new_word = substitute(new_word, escape(a:style, '*_') . '$', '', '')
            else
                let new_word = a:style . word . a:style
            endif
            let new_line = strpart(line_text, 0, start) . new_word . strpart(line_text, end)
            call setline(lnum, new_line)
            call cursor(lnum, start + 1)
        endif
    endif
endfunction

function! s:remove_style_at_cursor(style, lnum, col) abort
    let line_text = getline(a:lnum)
    let style_escaped = escape(a:style, '*_')
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

function! s:remove_style_if_overlaps(style, lnum1, col1, lnum2, col2) abort
    let style_escaped = escape(a:style, '*_')
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

function! s:remove_inline_code_at_cursor(lnum, col) abort
    let line_text = getline(a:lnum)
    let pattern = '`.\{-}`'
    let start = 0
    while 1
        let match_pos = matchstrpos(line_text, pattern, start)
        if empty(match_pos[0])
            break
        endif
        let [matched, mstart, mend] = [match_pos[0], match_pos[1], match_pos[2]]
        if a:col-1 >= mstart && a:col-1 < mend
            let text_without_code = strpart(line_text, mstart + 1, mend - mstart - 2)
            let new_line = strpart(line_text, 0, mstart) . text_without_code . strpart(line_text, mend)
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