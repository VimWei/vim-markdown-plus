" 生成带时间戳的 todo 字符串
function! markdown_plus#snippets#GenerateTodoString() abort
    let l:symbols = markdown_plus#util#GetListSymbols()
    let l:pattern = markdown_plus#util#GetListPattern()
    let l:line = getline('.')
    let l:indent = matchstr(l:line, '^\s*')
    let content = substitute(l:line, '^\s*', '', '')
    let l:timestamp = strftime("%Y-%m-%d %A")

    if content =~ l:pattern . '\s*\[\s*[ x]\s*\]'
        let prefix = matchstr(content, l:pattern)
        let rest = substitute(content, '^' . escape(prefix, '.*+?^$()[]{}|\\') . '\s*\[\s*[ x]\s*\]\s*', '', '')
        let todo_replacement = l:timestamp
    elseif content =~ l:pattern
        let prefix = matchstr(content, l:pattern)
        let rest = substitute(content, '^' . escape(prefix, '.*+?^$()[]{}|\\') . '\s*', '', '')
        let todo_replacement = '[ ] ' . l:timestamp
    else
        let prefix = l:symbols[0]
        let rest = substitute(content, '^\s*', '', '')
        let todo_replacement = prefix . ' [ ] ' . l:timestamp
    endif

    return todo_replacement
endfunction 