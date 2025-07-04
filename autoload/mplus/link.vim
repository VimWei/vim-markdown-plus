vim9script

export def WikiLinkToggle(type: string)
    echomsg "--- WikiLinkToggle START ---"
    echomsg printf("Function called with type: %s", type)

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
        echomsg printf("Selection Start Pos (\'[): %s", string(sel_start_pos))
        echomsg printf("Selection End Pos (\']): %s", string(sel_end_pos))

        # If the marks are invalid (e.g., no previous selection/operator),
        # we can't determine a range, so we default to creating a link.
        if sel_start_pos[1] == 0 && sel_start_pos[2] == 0
            echomsg "Invalid selection marks. Defaulting to transform_operator."
            wiki#link#transform_operator(type)
            return
        endif

        var links_on_lines = wiki#link#get_all_from_range(sel_start_pos[1], sel_end_pos[1])
        echomsg printf("Found %d links on lines %d-%d", len(links_on_lines), sel_start_pos[1], sel_end_pos[1])
        var links_to_delete = []

        # Determine if the original operation was linewise (for deletion logic).
        # This is based on the 'type' argument passed to the operator function.
        var is_linewise_op_or_visual = type == 'line' || type == 'V'
        echomsg printf("Is linewise operation/visual: %s", string(is_linewise_op_or_visual))

        for link in links_on_lines
            echomsg printf("Checking link: %s (pos: %s)", link.text, string(link.pos_start))
            # If the original operation was linewise, all links on the selected lines are targeted for deletion.
            if is_linewise_op_or_visual
                echomsg "Linewise operation/visual, adding link to delete queue."
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
                echomsg "Link is IN selection. Adding to delete queue."
                add(links_to_delete, link)
            else
                echomsg "Link is NOT in selection."
            endif
        endfor

        if !empty(links_to_delete)
            echomsg printf("ACTION: Deleting %d links.", len(links_to_delete))
            # Intent: REMOVE links inside the selection.
            for link in reverse(links_to_delete)
                echomsg printf("Deleting link at pos: %s", string(link.pos_start))
                setpos('.', [0, link.pos_start[0], link.pos_start[1], 0])
                wiki#link#remove()
            endfor
        else
            echomsg "No links to delete. Proceeding to create link."
            # If in visual mode, re-select the visual range and yank it into the unnamed register.
            # This ensures wiki#link#transform_operator gets the correct content.
            # 'type' will be 'v', 'V', or '^V' in visual mode.
            if type == 'v' || type == 'V' || type == '^V'
                echomsg printf("In visual mode (%s), yanking selection to unnamed register.", type)
                normal! gvy
            else
                echomsg printf("In operator mode (%s), text should already be in unnamed register.", type)
            endif
            # For operator mode, Vim automatically puts the operated text into the unnamed register.
            # Now, delegate to the original function for link creation.
            echomsg printf("Calling wiki#link#transform_operator with type: %s", type)
            wiki#link#transform_operator(type)
        endif
    finally
        # 4. Sandbox: ALWAYS restore the clipboard to its original state.
        #    This cleans up any pollution from the wiki.vim functions and
        #    prevents our function from affecting subsequent user actions.
        call setreg('"', save_reg, save_reg_type)
        echomsg "--- WikiLinkToggle END ---"
    endtry
    Redir#redir('messages', 0, 0, 0)
enddef
