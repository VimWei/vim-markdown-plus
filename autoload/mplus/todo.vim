vim9script

import autoload './list.vim' as list

var checkbox_symbols = get(g:, 'markdown_checkbox_symbols', ' .oOxX-')
var todo_status = map(split(checkbox_symbols, '\zs'), (_, c) => '[' .. c .. ']')

def DefaultCheckboxFallback(fl: number, nr: number): string
    CheckboxToggle(fl + nr, fl + nr)
    return getline(fl + nr)
enddef

def DoneHandler(line: string, fl: number, nr: number): string
    if line =~# '\[ \]'
        return substitute(line, '\[ \]', '[x]', '')
    elseif line =~# '\[x\]' || line =~# '\[X\]'
        return substitute(line, '\[[xX]\]', '[ ]', '')
    elseif line =~# '\[[^\]]\]'
        return substitute(line, '\[[^\]]\]', '[x]', '')
    else
        return DefaultCheckboxFallback(fl, nr)
    endif
enddef

def SuspendHandler(line: string, fl: number, nr: number): string
    if line =~# '\[-\]'
        return substitute(line, '\[-\]', '[ ]', '')
    elseif line =~# '\[[^\]]\]'
        return substitute(line, '\[\([^\]]\)\]', '[-]', '')
    else
        var newline = DefaultCheckboxFallback(fl, nr)
        return substitute(newline, '\[ \]', '[-]', '')
    endif
enddef

def MaturityNextHandler(line: string, fl: number, nr: number): string
    var states = filter(copy(todo_status), (_, v) => v !=# '[-]')
    if index(states, '[x]') >= 0 && index(states, '[X]') >= 0
        states = filter(states, (_, v) => v !=# '[X]')
    endif
    var m = matchlist(line, '\[[^\]]\]')
    if !empty(m)
        var current = m[0]
        var idx = index(states, current)
        if idx >= 0 && idx < len(states) - 1
            return substitute(line, '\[.\]', states[idx + 1], '')
        endif
        return line
    endif
    return DefaultCheckboxFallback(fl, nr)
enddef

def MaturityPrevHandler(line: string, fl: number, nr: number): string
    var states = filter(copy(todo_status), (_, v) => v !=# '[-]')
    if index(states, '[x]') >= 0 && index(states, '[X]') >= 0
        states = filter(states, (_, v) => v !=# '[X]')
    endif
    var m = matchlist(line, '\[[^\]]\]')
    if !empty(m)
        var current = m[0]
        if current ==# '[X]'
            current = '[x]'
        endif
        var idx = index(states, current)
        if idx > 0
            return substitute(line, '\[.\]', states[idx - 1], '')
        endif
        return line
    endif
    return DefaultCheckboxFallback(fl, nr)
enddef

def ToggleLines(firstline: number, lastline: number, ProcessLine: func): void
    var lines = getline(firstline, lastline)
    var result = []
    var nr = 0
    for line in lines
        add(result, ProcessLine(line, firstline, nr))
        nr += 1
    endfor
    setline(firstline, result)
enddef

# CheckboxToggle ---------------------------------------------------------{{{1
export def CheckboxToggle(firstline: number, lastline: number)
    var symbols = list.GetListSymbols()
    var pattern = list.GetListPattern()
    var state_pattern = '\\v' .. join(map(copy(todo_status), (i, v) => escape(v, '[]')), '|')
    var lines = getline(firstline, lastline)
    var result = []
    for line in lines
        var indent = matchstr(line, '^\s*')
        var content = substitute(line, '^\s*', '', '')
        var new_line = ''
        var ml = matchlist(content, '\v^(' .. pattern .. '\s*)(' .. state_pattern .. ')\s*(.*)$')
        if !empty(ml)
            var prefix = ml[1]->substitute('\s*$', '', '')
            var rest = ml[4]
            new_line = indent .. prefix .. (rest == '' ? '' : ' ' .. rest)
        elseif content =~ pattern
            var prefix = matchstr(content, pattern)
            var full_prefix_match = matchstr(content, pattern .. '\s*')
            var rest = strpart(content, len(full_prefix_match))
            new_line = indent .. prefix .. ' [ ] ' .. rest
        else
            new_line = indent .. symbols[0] .. ' [ ] ' .. substitute(content, '^\s*', '', '')
        endif
        add(result, new_line)
    endfor
    setline(firstline, result)
enddef

# DoneToggle ([ ] <-> [x]) -----------------------------------------------{{{1
export def DoneToggle(firstline: number, lastline: number)
    ToggleLines(firstline, lastline, function('DoneHandler'))
enddef

# SuspendToggle ([ ] <-> [-]) --------------------------------------------{{{1
export def SuspendToggle(firstline: number, lastline: number)
    ToggleLines(firstline, lastline, function('SuspendHandler'))
enddef

# MaturityNext ([ ] -> [.] -> [o] -> [O] -> [x]) -------------------------{{{1
export def MaturityNext(firstline: number, lastline: number)
    ToggleLines(firstline, lastline, function('MaturityNextHandler'))
enddef

# MaturityPrevious ([x] -> [O] -> [o] -> [.] -> [ ]) ---------------------{{{1
export def MaturityPrevious(firstline: number, lastline: number)
    ToggleLines(firstline, lastline, function('MaturityPrevHandler'))
enddef
