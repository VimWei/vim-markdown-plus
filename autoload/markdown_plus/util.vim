let s:markdown_list_symbols = [
    \ '*',
    \ '-',
    \ '+',
    \ '1.',
    \ 'a.',
    \ 'A.',
    \ 'i.',
    \ 'I.',
    \ ]

let s:markdown_list_pattern = '\v^(' . join(map(copy(s:markdown_list_symbols), 'escape(v:val, ".*+?^$()[]{}|\\")'), '|') . ')'

function! markdown_plus#util#GetListSymbols() abort
    return copy(s:markdown_list_symbols)
endfunction

function! markdown_plus#util#GetListPattern() abort
    return s:markdown_list_pattern
endfunction 