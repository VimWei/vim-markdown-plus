function! markdown_plus#code#WrapInCodeBlock() range
    let lines = getline(a:firstline, a:lastline)
    let result = []

    call add(result, '```')
    call extend(result, lines)
    call add(result, '```')

    execute a:firstline . ',' . a:lastline . 'delete'
    call append(a:firstline - 1, result)
endfunction
 