if !exists('g:markdown_plus_checkbox_states')
  let g:markdown_plus_checkbox_states = ['[ ]', '[.]', '[o]', '[x]', '[-]']
endif

function! markdown_plus#checkbox#ToggleTodoCheckbox() range
    let l:symbols = markdown_plus#util#GetListSymbols()
    let l:pattern = markdown_plus#util#GetListPattern()
    let lines = getline(a:firstline, a:lastline)
    let result = []

    for line in lines
        let indent = matchstr(line, '^\s*')
        let content = substitute(line, '^\s*', '', '')

        if content =~ l:pattern . '\s*\[\s*[ x]\s*\]'
            let prefix = matchstr(content, l:pattern)
            let full_prefix_match = matchstr(content, l:pattern . '\s*\[\s*[ x]\s*\]\s*')
            let rest = strpart(content, len(full_prefix_match))
            let new_line = indent . prefix . ' ' . rest
        elseif content =~ l:pattern
            let prefix = matchstr(content, l:pattern)
            let full_prefix_match = matchstr(content, l:pattern . '\s*')
            let rest = strpart(content, len(full_prefix_match))
            let new_line = indent . prefix . ' [ ] ' . rest
        else
            let new_line = indent . l:symbols[0] . ' [ ] ' . substitute(content, '^\s*', '', '')
        endif

        call add(result, new_line)
    endfor

    call setline(a:firstline, result)
endfunction

function! markdown_plus#checkbox#ToggleCheckboxState() range
  let states = g:markdown_plus_checkbox_states
  let lines = getline(a:firstline, a:lastline)
  let result = []
  let state_pat = '\v\[.\]'
  for line in lines
    let m = matchlist(line, state_pat)
    if !empty(m)
      let cur = m[0]
      let idx = index(states, cur)
      if idx == -1
        let next = states[0]
      else
        let next = states[(idx+1)%len(states)]
      endif
      let newline = substitute(line, state_pat, next, '')
    else
      let newline = line
    endif
    call add(result, newline)
  endfor
  call setline(a:firstline, result)
endfunction

function! markdown_plus#checkbox#ToggleDoneStatus() range
  let lines = getline(a:firstline, a:lastline)
  let result = []
  for line in lines
    if line =~# '\[ \]'
      let newline = substitute(line, '\[ \]', '[x]', '')
    elseif line =~# '\[x\]'
      let newline = substitute(line, '\[x\]', '[ ]', '')
    else
      let newline = line
    endif
    call add(result, newline)
  endfor
  call setline(a:firstline, result)
endfunction

function! markdown_plus#checkbox#ToggleRejectedStatus() range
  let lines = getline(a:firstline, a:lastline)
  let result = []
  for line in lines
    if line =~# '\[ \]'
      let newline = substitute(line, '\[ \]', '[-]', '')
    elseif line =~# '\[-\]'
      let newline = substitute(line, '\[-\]', '[ ]', '')
    else
      let newline = line
    endif
    call add(result, newline)
  endfor
  call setline(a:firstline, result)
endfunction

function! markdown_plus#checkbox#IncreaseDoneStatus() range
  let states = ['[ ]', '[.]', '[o]', '[x]']
  let lines = getline(a:firstline, a:lastline)
  let result = []
  for line in lines
    let found = 0
    for idx in range(len(states))
      if line =~# states[idx]
        let found = 1
        if idx < len(states)-1
          let newline = substitute(line, states[idx], states[idx+1], '')
        else
          let newline = line
        endif
        break
      endif
    endfor
    if !found
      let newline = line
    endif
    call add(result, newline)
  endfor
  call setline(a:firstline, result)
endfunction

function! markdown_plus#checkbox#DecreaseDoneStatus() range
  let states = ['[ ]', '[.]', '[o]', '[x]']
  let lines = getline(a:firstline, a:lastline)
  let result = []
  for line in lines
    let found = 0
    for idx in range(len(states))
      if line =~# states[idx]
        let found = 1
        if idx > 0
          let newline = substitute(line, states[idx], states[idx-1], '')
        else
          let newline = line
        endif
        break
      endif
    endfor
    if !found
      let newline = line
    endif
    call add(result, newline)
  endfor
  call setline(a:firstline, result)
endfunction