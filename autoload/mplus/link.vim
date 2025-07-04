vim9script

export def WikiLinkToggle(type: string)
    # --- The Definitive Solution: Isolate State Pollution ---
    # wiki.vim functions pollute the clipboard (unnamed register) . The
    # solution is to create a "sandbox" for our function.

    # 1. Sandbox: Save the clipboard state.
    var save_reg = getreg('"')
    var save_reg_type = getregtype('"')

    try
        # Use the '[ and '] marks, which Vim sets for the last operated-on or
        # visually selected text. This works for both visual mode and operators.
        var sel_start_pos = getpos("'[")
        var sel_end_pos = getpos("']")

        # If the marks are invalid (e.g., no previous selection/operator),
        # we can't determine a range, so we default to creating a link.
        if sel_start_pos[1] == 0 && sel_start_pos[2] == 0
            wiki#link#transform_operator(type)
            return
        endif

        var links_on_lines = wiki#link#get_all_from_range(sel_start_pos[1], sel_end_pos[1])
        var links_to_delete = []

        for link in links_on_lines
            # For linewise selection, all links on the selected lines are targeted.
            if visualmode() == 'V'
                add(links_to_delete, link)
                continue
            endif

            # For charwise and blockwise selection, check for overlap.
            var l = link.pos_start[0]
            var ls = link.pos_start[1]
            var le = link.pos_end[1]

            var ssl = sel_start_pos[1]
            var ssc = sel_start_pos[2]
            var sel = sel_end_pos[1]
            var sec = sel_end_pos[2]

            var is_in_selection = false
            if l > ssl && l < sel # Link is on a line fully within the selection
                is_in_selection = true
            elseif l == ssl && l < sel # Link is on the first line of a multi-line selection
                if le > ssc
                    is_in_selection = true
                endif
            elseif l > ssl && l == sel # Link is on the last line of a multi-line selection
                if ls < sec
                    is_in_selection = true
                endif
            elseif l == ssl && l == sel # Link is on the same line as the selection
                if max([ls, ssc]) < min([le, sec])
                    is_in_selection = true
                endif
            endif

            if is_in_selection
                add(links_to_delete, link)
            endif
        endfor

        if !empty(links_to_delete)
            # Intent: REMOVE links inside the selection.
            for link in reverse(links_to_delete)
                setpos('.', [0, link.pos_start[0], link.pos_start[1], 0])
                wiki#link#remove()
            endfor
        else
            # Intent: CREATE a new link using the operator's motion.
            wiki#link#transform_operator(type)
        endif
    finally
        # 4. Sandbox: ALWAYS restore the clipboard to its original state.
        #    This cleans up any pollution from the wiki.vim functions and
        #    prevents our function from affecting subsequent user actions.
        call setreg('"', save_reg, save_reg_type)
    endtry
enddef
