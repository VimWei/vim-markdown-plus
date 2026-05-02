vim9script

import autoload './text.vim' as text

var items: list<dict<any>> = [
    {label: 'Delete lines starting with ---', cmd: '', enabled: true},
    {label: 'Promote H3+ headings by one level', cmd: '{range}s/###/##/g', enabled: true},
    {label: 'Add empty line after H2+ headings', cmd: '', enabled: true},
    {label: 'Remove all markdown text style', cmd: '', enabled: true},
    {label: 'Remove leading 2 spaces', cmd: '{range}s/^  //g', enabled: true},
    {label: 'Remove spaces after Chinese colon', cmd: '{range}s/： /：/g', enabled: true},
    {label: 'Remove redundant spaces after numbered list', cmd: '{range}s/\(\d\.\)\s\+/\1 /g', enabled: true},
    {label: 'Remove backslash in numbered lists', cmd: '{range}s/\(\d\+\)\\\(\.\)/\1\2/g', enabled: true},
]

var exec_order: list<number> = [0, 1, 2, 3, 4, 5, 6, 7]

export def Run(firstline: number, lastline: number)
    var cmd_range: string = '%'
    var start_line: number = 1
    var end_line: number = line('$')

    var visual_start: number = line("'<")
    var visual_end: number = line("'>")

    if firstline != lastline
        if firstline == visual_start && lastline == visual_end
            cmd_range = "'<,'>"
        endif
        start_line = firstline
        end_line = lastline
    elseif firstline == visual_start && lastline == visual_end
        # Single line visual selection
        cmd_range = "'<,'>"
        start_line = firstline
        end_line = lastline
    endif

    while true
        var dialog_items: list<dict<any>> = []
        for i in range(items->len())
            add(dialog_items, {
                type: 'check',
                name: $'op_{i}',
                text: items[i].label,
                value: items[i].enabled,
            })
        endfor
        add(dialog_items, {
            type: 'button',
            name: 'action',
            items: [' &Execute ', ' &Reset ', ' &Cancel '],
        })

        var result = quickui#dialog#open(dialog_items, {title: 'LLMClean', focus: 'action'})

        if result.button_index < 0 || result.button_index == 2
            return
        endif

        if result.button_index == 1
            for item in items
                item.enabled = true
            endfor
            continue
        endif

        for i in range(items->len())
            items[i].enabled = result[$'op_{i}']
        endfor

        ExecuteItems(items, cmd_range, start_line, end_line)
        break
    endwhile

    # Ensure normal mode after execution
    silent! execute "normal! \<Esc>"
enddef

def ExecuteItems(ops: list<dict<any>>, cmd_range: string, start_line: number, end_line: number)
    var executed: number = 0
    var current_start: number = start_line
    var current_end: number = end_line

    for idx in exec_order
        if !ops[idx].enabled
            continue
        endif

        var lines_before: number = line('$')

        if idx == 3
            if &filetype != 'markdown'
                continue
            endif
            RemoveAllInRange(current_start, current_end, cmd_range)
            executed += 1
        elseif idx == 2
            AddEmptyLineAfterHeadings(current_start, current_end)
            executed += 1
        elseif idx == 0
            DeleteLinesStartingWith(current_start, current_end, '^---')
            executed += 1
        else
            var range_str: string = cmd_range == '%' ? '%' : $'{current_start},{current_end}'
            var cmd: string = ops[idx].cmd->substitute('{range}', range_str, 'g')
            silent! execute ':' .. cmd
            executed += 1
        endif

        var lines_after: number = line('$')
        var delta: number = lines_after - lines_before
        current_end += delta
    endfor

    if executed == 0
        echo 'No operation selected.'
    else
        echo $'LLMClean: {executed} operation(s) executed.'
    endif
enddef

def RemoveAllInRange(start_line: number, end_line: number, cmd_range: string)
    if cmd_range == '%'
        setpos("'[", [0, 1, 1, 0])
        setpos("']", [0, line('$'), strlen(getline('$')) + 1, 0])
    else
        setpos("'[", [0, start_line, 1, 0])
        setpos("']", [0, end_line, strlen(getline(end_line)) + 1, 0])
    endif
    text.RemoveAll('markdownRemoveAll')
    redraw!
enddef

def DeleteLinesStartingWith(start_line: number, end_line: number, pattern: string)
    var lnum: number = end_line
    while lnum >= start_line
        if getline(lnum) =~ pattern
            silent! execute $':{lnum}d'
        endif
        lnum -= 1
    endwhile
enddef

def AddEmptyLineAfterHeadings(start_line: number, end_line: number)
    var lnum: number = end_line
    while lnum >= start_line
        if getline(lnum) =~ '^##'
            var nextline: string = getline(lnum + 1)
            if nextline !~ '^$'
                append(lnum, '')
            endif
        endif
        lnum -= 1
    endwhile
enddef
