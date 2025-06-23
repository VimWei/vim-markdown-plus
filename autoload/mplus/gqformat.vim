" UngqFormat -------------------------------------------------------------{{{1
function! mplus#list#UngqFormat(start_line, end_line) range
    let l:start_line = a:start_line
    let l:end_line = a:end_line

    let textwidth_save = &textwidth
    set textwidth=0

    let reformatted_lines = []
    let list_item_regex = '^\s*\%(\d\+[.)]\|\a\+[.)]\|\c\mI\+[.)]\|-\|\*\|#\)\s'
    let chinese_char_regex = '[\u4e00-\u9fa5\·\！\，\。\？\；\：\“\”\‘\’\【\】\（\）\《\》\——\……\、]'

    let i = l:start_line
    while i <= l:end_line
        let line_text = getline(i)
        if line_text =~ list_item_regex
            if len(reformatted_lines) > 0 && reformatted_lines[-1] !~ list_item_regex && reformatted_lines[-1] !~ '^\s*$'
                call add(reformatted_lines, '')
            endif
            let list_block = line_text
            let i += 1
            while i <= l:end_line
                let next_line = getline(i)
                if next_line =~ '^\s*$' || next_line =~ list_item_regex
                    break
                endif
                let trimmed_next_line = substitute(next_line, '^\s\+', '', '')
                let last_char_of_current_line = matchstr(list_block, '.$')
                let first_char_of_next_line = matchstr(trimmed_next_line, '^\S')
                let space = ''
                if last_char_of_current_line =~ chinese_char_regex && first_char_of_next_line =~ chinese_char_regex
                    let space = ''
                else
                    let space = ' '
                endif
                let list_block .= space . trimmed_next_line
                let i += 1
            endwhile
            call add(reformatted_lines, list_block)
        else
            if line_text =~ '^\s*$'
                call add(reformatted_lines, line_text)
                let i += 1
            else
                let paragraph_block = line_text
                let i += 1
                while i <= l:end_line
                    let next_line = getline(i)
                    if next_line =~ '^\s*$' || next_line =~ list_item_regex
                        break
                    endif
                    let trimmed_next_line = substitute(next_line, '^\s\+', '', '')
                    let last_char_of_current_line = matchstr(paragraph_block, '.$')
                    let first_char_of_next_line = matchstr(trimmed_next_line, '^\S')
                    let space = ''
                    if last_char_of_current_line =~ chinese_char_regex && first_char_of_next_line =~ chinese_char_regex
                        let space = ''
                    else
                        let space = ' '
                    endif
                    let paragraph_block .= space . trimmed_next_line
                    let i += 1
                endwhile
                call add(reformatted_lines, paragraph_block)
            endif
        endif
    endwhile

    if l:start_line == 1 && l:end_line == line('$')
        %delete _
        call append(0, reformatted_lines)
        if getline('$') == ''
            execute '$d'
        endif
    else
        execute l:start_line . ',' . l:end_line . 'delete _'
        call append(l:start_line - 1, reformatted_lines)
    endif

    let &textwidth = textwidth_save
endfunction
