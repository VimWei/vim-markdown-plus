vim9script

export def WikiLinkToggle(type: string)
    # --- The Definitive Solution: Isolate State Pollution ---
    # wiki.vim functions pollute the clipboard (unnamed register) . The
    # solution is to create a "sandbox" for our function.

    # 1. Sandbox: Save the clipboard state.
    var save_reg = getreg('"')
    var save_reg_type = getregtype('"')

    try
        # 2. Reliably determine user intent by checking the cursor position.
        #    This avoids all bugs related to reading operator marks ('<, '>).
        var lnum = line('.')
        var cursor_bcol = col('.')
        var links_on_line: list<any> = wiki#link#get_all_from_range(lnum, lnum)
        var link_under_cursor: dict<any> = {}

        for link in links_on_line
            var link_start_bcol = link.pos_start[1]
            var link_end_bcol = link.pos_end[1]

            if cursor_bcol >= link_start_bcol && cursor_bcol < link_end_bcol
                link_under_cursor = link
                break
            endif
        endfor

        # 3. Execute the action based on the determined intent.
        if !empty(link_under_cursor)
            # Intent: REMOVE link under cursor.
            setpos('.', [0, link_under_cursor.pos_start[0], link_under_cursor.pos_start[1], 0])
            wiki#link#remove()
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
