vim9script

export def CheckAndSetFiletype()
  if &buftype ==# '' && &filetype ==# '' && @% ==# '' && bufnr('%') != 1
    setlocal filetype=markdown
  endif
enddef