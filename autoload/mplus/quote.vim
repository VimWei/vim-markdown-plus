vim9script

# ToggleQuoteBlock -------------------------------------------------------{{{1
export def ToggleQuoteBlock(firstline: number, lastline: number)
    var found_quoteblock = false
    var all_lines_quoted = true
    
    for lnum in range(firstline, lastline)
        var line = getline(lnum)
        var synname = synIDattr(synID(lnum, 1, 1), "name")
        
        # 检查是否为引用行（以 > 开头）或语法高亮为引用块
        var is_quoted = line =~# '^\s*>\s' || synname ==# 'markdownQuoteBlock'
        
        if !is_quoted
            all_lines_quoted = false
            break
        endif
    endfor
    
    # 只有当范围内的每一行都是引用行时，才认为是引用块
    found_quoteblock = all_lines_quoted
    
    if found_quoteblock
        echomsg $'ToggleQuoteBlock: UnsetQuoteBlock({firstline}, {lastline})'
        UnsetQuoteBlock(firstline, lastline)
    else
        echomsg $'ToggleQuoteBlock: SetQuoteBlock({firstline}, {lastline})'
        SetQuoteBlock(firstline, lastline)
    endif
enddef

# SetQuoteBlock ----------------------------------------------------------{{{1
export def SetQuoteBlock(firstline: number, lastline: number)
    for line_nr in range(firstline, lastline)
        var line_content = getline(line_nr)
        # 为所有行添加引用标记，确保整个范围都是引用块
        setline(line_nr, $'> {line_content}')
    endfor
enddef

# UnsetQuoteBlock --------------------------------------------------------{{{1
export def UnsetQuoteBlock(firstline: number, lastline: number)
    # 向上扩展找到引用块的开始
    var start_line = firstline
    while start_line > 1 && getline(start_line - 1) =~# '^\s*>\s'
        start_line -= 1
    endwhile
    
    # 向下扩展找到引用块的结束
    var end_line = lastline
    while end_line < line('$') && getline(end_line + 1) =~# '^\s*>\s'
        end_line += 1
    endwhile
    
    # 移除整个引用块的引用标记
    for lnum in range(start_line, end_line)
        var content = getline(lnum)
        # 移除开头的 > 和空格，保留行内容
        var new_content = content->substitute('^\s*>\s*', '', '')
        setline(lnum, new_content)
    endfor
enddef
