vim9script

import autoload './list.vim' as list

var checkbox_symbols = get(g:, 'markdown_checkbox_symbols', ' .oOxX-')
# var todo_status = ['[ ]', '[.]', '[o]', '[O]', '[x]', '[X]', '[-]']
var todo_status = map(split(checkbox_symbols, '\zs'), (_, c) => '[' .. c .. ']')

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
        # 检查是否是 todo 列表项（包含 [ ]、[x]、[.] 等标记）
        var ml = matchlist(content, '\v^(' .. pattern .. '\s*)(' .. state_pattern .. ')\s*(.*)$')
        if !empty(ml)
            var prefix = ml[1]->substitute('\s*$', '', '')
            var rest = ml[4]
            new_line = indent .. prefix .. (rest == '' ? '' : ' ' .. rest)
        elseif content =~ pattern
            # 是普通列表项，转换为 todo 列表项
            var prefix = matchstr(content, pattern)
            var full_prefix_match = matchstr(content, pattern .. '\s*')
            var rest = strpart(content, len(full_prefix_match))
            new_line = indent .. prefix .. ' [ ] ' .. rest
        else
            # 转换为带 todo 标记的列表项
            new_line = indent .. symbols[0] .. ' [ ] ' .. substitute(content, '^\s*', '', '')
        endif
        add(result, new_line)
    endfor
    setline(firstline, result)
enddef

# DoneToggle ([ ] <-> [x]) -----------------------------------------------{{{1
export def DoneToggle(firstline: number, lastline: number)
    var lines = getline(firstline, lastline)
    var result = []
    var nr = 0
    for line in lines
        var newline = ''
        if line =~# '\[ \]'
            newline = substitute(line, '\[ \]', '[x]', '')
        elseif line =~# '\[x\]' || line =~# '\[X\]'
            newline = substitute(line, '\[[xX]\]', '[ ]', '')
        elseif line =~# '\[[^\]]\]'
            # [.] [o] [O] [-] --> [x]
            newline = substitute(line, '\[[^\]]\]', '[x]', '')
        else
            # 非 checkbox，则使用 ToggleTodoCheckbox 将其转换
            CheckboxToggle(firstline + nr, firstline + nr)
            newline = getline(firstline + nr)
        endif
        add(result, newline)
        nr += 1
    endfor
    setline(firstline, result)
enddef

# SuspendToggle ([ ] <-> [-]) --------------------------------------------{{{1
export def SuspendToggle(firstline: number, lastline: number)
    var lines = getline(firstline, lastline)
    var result = []
    var nr = 0
    for line in lines
        var newline = ''
        if line =~# '\[-\]'
            # [-] --> [ ]
            newline = substitute(line, '\[-\]', '[ ]', '')
        elseif line =~# '\[[^\]]\]'
            # [.] [o] [O] [x] [X] [ ] --> [-]
            newline = substitute(line, '\[\([^\]]\)\]', '[-]', '')
        else
            # 非 checkbox，则使用 ToggleTodoCheckbox 将其转换
            CheckboxToggle(firstline + nr, firstline + nr)
            # 并将其中的 [ ] --> [-]
            newline = getline(firstline + nr)
            newline = substitute(newline, '\[ \]', '[-]', '')
        endif
        add(result, newline)
        nr += 1
    endfor
    setline(firstline, result)
enddef

# MaturityNext ([ ] -> [.] -> [o] -> [O] -> [x]) -------------------------{{{1
export def MaturityNext(firstline: number, lastline: number)
    # 排除 [-] 以及 [X]（前提是同时存在 [x] 和 [X]）
    var states = filter(copy(todo_status), (_, v) => v !=# '[-]')
    if index(states, '[x]') >= 0 && index(states, '[X]') >= 0
        states = filter(states, (_, v) => v !=# '[X]')
    endif
    var lines = getline(firstline, lastline)
    var result = []
    var nr = 0
    for line in lines
        var m = matchlist(line, '\[[^\]]\]')
        if !empty(m)
            var current = m[0]
            var idx = index(states, current)
            if idx >= 0 && idx < len(states) - 1
                # 如果是已知状态，且不是最后一个状态，则推进到下一个状态
                var newline = substitute(line, '\[.\]', states[idx + 1], '')
                add(result, newline)
            else
                # 如果不是已知状态，或是最后一个状态，保持不变
                add(result, line)
            endif
        else
            # 如果没有 checkbox，则使用 ToggleTodoCheckbox 将其转换
            CheckboxToggle(firstline + nr, firstline + nr)
            add(result, getline(firstline + nr))
        endif
        nr += 1
    endfor
    setline(firstline, result)
enddef

# MaturityPrevious ([x] -> [O] -> [o] -> [.] -> [ ]) ---------------------{{{1
export def MaturityPrevious(firstline: number, lastline: number)
    # 排除 [-] 以及 [X]（前提是同时存在 [x] 和 [X]）
    var states = filter(copy(todo_status), (_, v) => v !=# '[-]')
    if index(states, '[x]') >= 0 && index(states, '[X]') >= 0
        states = filter(states, (_, v) => v !=# '[X]')
    endif
    var lines = getline(firstline, lastline)
    var result = []
    var nr = 0
    for line in lines
        var m = matchlist(line, '\[[^\]]\]')
        if !empty(m)
            var current = m[0]
            # 先将 [X] 标准化为 [x]
            if current ==# '[X]'
                current = '[x]'
            endif
            var idx = index(states, current)
            if idx > 0
                # 如果是已知状态，且不是第一个状态，则退回到前一个状态
                var newline = substitute(line, '\[.\]', states[idx - 1], '')
                add(result, newline)
            else
                # 如果不是已知状态，或是第一个状态，保持不变
                add(result, line)
            endif
        else
            # 如果没有 checkbox，则使用 ToggleTodoCheckbox 将其转换
            CheckboxToggle(firstline + nr, firstline + nr)
            add(result, getline(firstline + nr))
        endif
        nr += 1
    endfor
    setline(firstline, result)
enddef
