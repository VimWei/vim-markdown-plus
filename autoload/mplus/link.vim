vim9script

import autoload './utils.vim' as utils

# Unified function for toggling links ------------------------------------{{{1
export def ToggleLink(link_type: string, type: string)
    # --- Dependency check ---
    if !exists('g:wiki_loaded')
        utils.Echowarn("Missing dependency: lervag/wiki.vim")
        return
    endif

    # --- Save clipboard state (sandbox) ---
    var save_reg = getreg('"')
    var save_reg_type = getregtype('"')

    try
        # --- Get selection positions ---
        # Use the '[ and '] marks, which Vim sets for the last operated-on or
        # visually selected text. This works for both visual mode and operators.
        var sel_start_pos = getpos("'[")
        var sel_end_pos = getpos("']")

        # --- Validate selection marks ---
        if sel_start_pos[1] == 0 && sel_start_pos[2] == 0
            # Invalid selection marks, abort
            return
        endif

        # --- Determine if operation is linewise (for deletion logic) ---
        var is_linewise_op_or_visual = type == 'line' || type == 'V'

        # --- Find all links in the selected range ---
        var links_on_lines = wiki#link#get_all_from_range(sel_start_pos[1], sel_end_pos[1])
        var links_to_delete = []

        # --- Collect links that overlap with the selection ---
        for link in links_on_lines
            var is_in_selection = false
            if is_linewise_op_or_visual
                is_in_selection = true
            else
                var l = link.pos_start[0]
                var ls = link.pos_start[1]
                var le = link.pos_end[1]
                var ssl = sel_start_pos[1]
                var ssc = sel_start_pos[2]
                var sel = sel_end_pos[1]
                var sec = sel_end_pos[2]
                if l > ssl && l < sel
                    is_in_selection = true
                elseif l == ssl && l < sel
                    if le > ssc
                        is_in_selection = true
                    endif
                elseif l > ssl && l == sel
                    if ls < sec
                        is_in_selection = true
                    endif
                elseif l == ssl && l == sel
                    if max([ls, ssc]) < min([le, sec])
                        is_in_selection = true
                    endif
                endif
            endif
            if is_in_selection
                add(links_to_delete, link)
            endif
        endfor

        # --- Delete links if any found, otherwise create new link ---
        if !empty(links_to_delete)
            for link in reverse(links_to_delete)
                setpos('.', [0, link.pos_start[0], link.pos_start[1], 0])
                wiki#link#remove()
            endfor
        else
            if link_type == 'wiki'
                Create_wiki_link(type)
            elseif link_type == 'file'
                Create_file_link(type)
            elseif link_type == 'image'
                Create_image_link(type)
            else
                # Unknown link_type, do nothing
            endif
        endif
    finally
        # --- Restore clipboard state (sandbox) ---
        call setreg('"', save_reg, save_reg_type)
    endtry
    # Redir#redir('messages', 0, 0, 0)
enddef

# Create a wiki link -----------------------------------------------------{{{1
def Create_wiki_link(type: string)
    # re-uses wiki.vim functions
    if type == 'v' || type == 'V' || type == '^V'
        wiki#link#transform_visual()
    else
        wiki#link#transform_operator(type)
    endif
enddef

# Get selected text and context for link creation ------------------------{{{1
def Get_selected_text_and_context(): dict<any>
    # --- Get selection positions and lines ---
    var sel_start = getpos("'[")
    var sel_end = getpos("']")
    var start_line_num = sel_start[1]
    var end_line_num = sel_end[1]
    var lines = getline(start_line_num, end_line_num)

    # --- Convert byte column to character column ---
    var start_col_char = charidx(lines[0], sel_start[2] - 1) + 1
    var end_col_char = charidx(lines[-1], sel_end[2] - 1) + 1

    # --- Prepare prefix and suffix for replacement ---
    var before = strcharpart(lines[0], 0, start_col_char - 1)
    var after = strcharpart(lines[-1], end_col_char)

    # --- Build the selected text for the link ---
    var selected = ''
    var cjk_regex = '[一-龥ぁ-ゔァ-ヴー々〆〤가-힣]'
    if len(lines) == 1
        # Single line selection
        var line_len = strchars(lines[0])
        var safe_start = min([start_col_char - 1, line_len])
        var safe_len = min([end_col_char - start_col_char + 1, line_len - safe_start])
        selected = strcharpart(lines[0], safe_start, safe_len)
    else
        # Multi-line selection
        # 1. First line: only the selected part
        var first_line_len = strchars(lines[0])
        var safe_start = min([start_col_char - 1, first_line_len])
        selected = strcharpart(lines[0], safe_start)
        # 2. Middle lines: join with smart spacing
        if len(lines) > 2
            for lnum in range(1, len(lines) - 1)
                var prev_last = matchstr(selected, '.$')
                var curr_first = matchstr(lines[lnum], '^.')
                if prev_last =~# cjk_regex && curr_first =~# cjk_regex
                    selected ..= lines[lnum]
                else
                    selected ..= ' ' .. lines[lnum]
                endif
            endfor
        endif
        # 3. Last line: only the selected part, join with smart spacing
        var last_line_len = strchars(lines[-1])
        var safe_end_col_char = min([end_col_char, last_line_len])
        var last_part = strcharpart(lines[-1], 0, safe_end_col_char)
        var prev_last = matchstr(selected, '.$')
        var curr_first = matchstr(last_part, '^.')
        if prev_last =~# cjk_regex && curr_first =~# cjk_regex
            selected ..= last_part
        else
            selected ..= ' ' .. last_part
        endif
    endif
    # Remove NUL characters (safety)
    selected = substitute(selected, '\%x00', '', 'g')

    # --- Generate filename using wiki.vim's url_transform mechanism ---
    var creator = call('wiki#link#get_creator', [])
    var filename = selected
    if has_key(creator, 'url_transform')
        try
            filename = call(creator.url_transform, [selected])
        catch
            call wiki#log#warn('There was a problem with the url transformer!')
        endtry
    endif

    return {
        before: before,
        selected: selected,
        after: after,
        start_line_num: start_line_num,
        end_line_num: end_line_num,
        lines: lines,
        filename: filename,
    }
enddef

# Replace selection with new link and set cursor position ----------------{{{1
def Replace_selection_with_link(new_link: string, before: string, after: string,
                               start_line_num: number, end_line_num: number,
                               cursor_offset: number = 0)
    var new_line = before .. new_link .. after
    setline(start_line_num, new_line)
    if end_line_num > start_line_num
        call deletebufline('%', start_line_num + 1, end_line_num)
    endif

    # --- Place cursor at specified offset (multibyte safe) ---
    if cursor_offset > 0
        var cursor_pos = strchars(before) + cursor_offset
        setcursorcharpos([start_line_num, cursor_pos])
    endif
enddef

# Create a file link -----------------------------------------------------{{{1
def Create_file_link(type: string)
    var ctx = Get_selected_text_and_context()
    if empty(ctx.selected)
        return
    endif

    var new_link = printf('[%s](file:%s)', ctx.selected, ctx.filename)
    var cursor_offset = strchars(printf('[%s](', ctx.selected)) + 1
    Replace_selection_with_link(new_link, ctx.before, ctx.after,
                               ctx.start_line_num, ctx.end_line_num, cursor_offset)
enddef

# Create an image link ---------------------------------------------------{{{1
def Create_image_link(type: string)
    var ctx = Get_selected_text_and_context()
    if empty(ctx.selected)
        return
    endif

    var new_link = printf('![%s](%s)', ctx.selected, ctx.filename)
    var cursor_offset = strchars(printf('![%s](', ctx.selected)) + 1
    Replace_selection_with_link(new_link, ctx.before, ctx.after,
                               ctx.start_line_num, ctx.end_line_num, cursor_offset)
enddef
