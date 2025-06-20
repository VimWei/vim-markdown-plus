 function! markdown_plus#CheckAndSetFiletype() abort
  if &buftype ==# '' && &filetype ==# '' && @% ==# '' && bufnr('%') != 1
    setlocal filetype=markdown
  endif
endfunction