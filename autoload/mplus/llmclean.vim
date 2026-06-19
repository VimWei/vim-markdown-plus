vim9script

import autoload './text.vim' as text

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

def AddEmptyLineAfterHeadings(start_line: number, end_line: number, _: string = '')
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

def DeleteLinesMatching(start_line: number, end_line: number, cmd_range: string, pattern: string = '^---')
    var lnum: number = end_line
    while lnum >= start_line
        if getline(lnum) =~ pattern
            silent! execute $':{lnum}d'
        endif
        lnum -= 1
    endwhile
enddef

def DeleteEmptyLineBeforeCodeblockEnd(start_line: number, end_line: number, _: string = '')
    var lnum: number = end_line
    while lnum >= start_line
        if getline(lnum) =~ '^```'
            if lnum > 1 && getline(lnum - 1) =~ '^$'
                silent! execute $':{lnum - 1}d'
            endif
        endif
        lnum -= 1
    endwhile
enddef

def TrimChinesePunctSpaces(start_line: number, end_line: number, _: string = '')
    var punct_pattern: string = '[：，、；。？]'
    var lnum: number = end_line
    while lnum >= start_line
        var line_text: string = getline(lnum)
        var new_text: string = line_text->substitute($'\s\+\ze{punct_pattern}', '', 'g')
        new_text = new_text->substitute($'{punct_pattern}\zs\s\+', '', 'g')
        if line_text != new_text
            silent! call setline(lnum, new_text)
        endif
        lnum -= 1
    endwhile
enddef

def RemoveRedundantSpacesAfterList(start_line: number, end_line: number, _: string = '')
    var lnum: number = end_line
    while lnum >= start_line
        var line_text: string = getline(lnum)
        var new_text: string = line_text->substitute('\(\d\.\)\s\+', '\1 ', 'g')
        new_text = new_text->substitute('\([\*\-\+]\s\)\s\+', '\1', 'g')
        if line_text != new_text
            silent! call setline(lnum, new_text)
        endif
        lnum -= 1
    endwhile
enddef

var items: list<dict<any>> = [
    {label: 'Remove all markdown text style', cmd: '', enabled: true,
        Fn: function('RemoveAllInRange')},
    {label: 'Promote H3+ headings by one level', cmd: '{range}s/###/##/g', enabled: true},
    {label: 'Add empty line after H2+ headings', cmd: '', enabled: true,
        Fn: function('AddEmptyLineAfterHeadings')},
    {label: 'Delete lines matching ---', cmd: '', enabled: true,
        Fn: function('DeleteLinesMatching')},
    {label: 'Delete empty line before codeblock end', cmd: '', enabled: true,
        Fn: function('DeleteEmptyLineBeforeCodeblockEnd')},
    {label: 'Remove citation markers like [1] or [3, 4]', cmd: '{range}s/\s\+\[\d.\{-}\]//g', enabled: true},
    {label: 'Remove spaces around Chinese punctuation', cmd: '', enabled: true,
        Fn: function('TrimChinesePunctSpaces')},
    {label: 'Remove backslash in numbered lists', cmd: '{range}s/\(\d\+\)\\\(\.\)/\1\2/g', enabled: true},
    {label: 'Remove redundant spaces after list', cmd: '', enabled: true,
        Fn: function('RemoveRedundantSpacesAfterList')},
    {label: 'Remove leading 2 spaces', cmd: '{range}s/^  //g', enabled: false},
]

var defaults: list<bool> = items->copy()->map((_, v) => v.enabled)

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
            focus: 0,
            items: [' &Execute ', ' &Reset ', ' &Cancel '],
        })

        var result = quickui#dialog#open(dialog_items, {title: 'LLMClean'})

        if result.button_index < 0 || result.button_index == 2
            return
        endif

        if result.button_index == 1
            for i in range(items->len())
                items[i].enabled = defaults[i]
            endfor
            continue
        endif

        for i in range(items->len())
            items[i].enabled = result[$'op_{i}']
        endfor

        ExecuteItems(items, cmd_range, start_line, end_line)
        break
    endwhile

    silent! execute "normal! \<Esc>"
enddef

def ExecuteItems(ops: list<dict<any>>, cmd_range: string, start_line: number, end_line: number)
    var executed: number = 0
    var current_start: number = start_line
    var current_end: number = end_line

    for item in ops
        if !item.enabled
            continue
        endif

        var lines_before: number = line('$')

        if has_key(item, 'Fn')
            call(item.Fn, [current_start, current_end, cmd_range])
        elseif !empty(get(item, 'cmd', ''))
            var range_str: string = cmd_range == '%' ? '%' : $'{current_start},{current_end}'
            var cmd: string = item.cmd->substitute('{range}', range_str, 'g')
            silent! execute ':' .. cmd
        endif

        executed += 1
        var lines_after: number = line('$')
        current_end += lines_after - lines_before
    endfor

    if executed == 0
        echo 'No operation selected.'
    else
        echo $'LLMClean: {executed} operation(s) executed.'
    endif
enddef
