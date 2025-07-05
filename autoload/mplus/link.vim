vim9script

# Unified function for toggling links
export def ToggleLink(link_type: string, type: string)
    echomsg "--- ToggleLink START ---"
    echomsg printf("ToggleLink called with link_type: %s, type: %s", link_type, type)

    # 1. Sandbox: Save the clipboard state.
    var save_reg = getreg('"')
    var save_reg_type = getregtype('"')

    try
        # Use the '[ and '] marks, which Vim sets for the last operated-on or
        # visually selected text. This works for both visual mode and operators.
        var sel_start_pos = getpos("'[")
        var sel_end_pos = getpos("']")
        # echomsg printf("Selection Start Pos (\'[): %s", string(sel_start_pos))
        # echomsg printf("Selection End Pos (\']): %s", string(sel_end_pos))

        # If no valid selection marks (i.e., not called via operator or visual mode),
        # try to create link from word under cursor.
        if sel_start_pos[1] == 0 && sel_start_pos[2] == 0
            echomsg "Invalid selection marks."
            return
        endif

        # Determine if the original operation was linewise (for deletion logic).
        var is_linewise_op_or_visual = type == 'line' || type == 'V'
        # echomsg printf("Is linewise operation/visual: %s", string(is_linewise_op_or_visual))

        var links_on_lines = wiki#link#get_all_from_range(sel_start_pos[1], sel_end_pos[1])
        # echomsg printf("Found %d links on lines %d-%d", len(links_on_lines), sel_start_pos[1], sel_end_pos[1])
        var links_to_delete = []

        for link in links_on_lines
            # echomsg printf("Checking link: %s (pos: %s, type: %s)", link.text, string(link.pos_start), link.type)
            # Now, any link found in the selection will be considered for deletion.

            var is_in_selection = false
            if is_linewise_op_or_visual
                # echomsg "Linewise operation/visual, adding link to delete queue."
                is_in_selection = true
            else
                # echomsg "Charwise/Blockwise operation: Checking for overlap."
                # Overlap logic
                var l = link.pos_start[0]
                var ls = link.pos_start[1]
                var le = link.pos_end[1]

                var ssl = sel_start_pos[1]
                var ssc = sel_start_pos[2]
                var sel = sel_end_pos[1]
                var sec = sel_end_pos[2]

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
            endif

            if is_in_selection
                # echomsg "Link is IN selection. Adding to delete queue."
                add(links_to_delete, link)
            endif
        endfor

        if !empty(links_to_delete)
            echomsg printf("ACTION: Deleting %d links.", len(links_to_delete))
            # Intent: REMOVE links inside the selection.
            for link in reverse(links_to_delete)
                # echomsg printf("Deleting link at pos: %s", string(link.pos_start))
                setpos('.', [0, link.pos_start[0], link.pos_start[1], 0])
                wiki#link#remove()
            endfor
        else
            echomsg "Create link from selection."
            if link_type == 'wiki'
                Create_wiki_link(type)
            elseif link_type == 'image'
                Create_image_link(type)
            else
                echomsg printf("Unknown link_type for creation: %s", link_type)
            endif
        endif
    finally
        # 4. Sandbox: ALWAYS restore the clipboard to its original state.
        call setreg('"', save_reg, save_reg_type)
        echomsg "--- ToggleLink END ---"
    endtry
    Redir#redir('messages', 0, 0, 0)
enddef

# Helper function to create a wiki link (re-uses wiki.vim functions)
def Create_wiki_link(type: string)
    # echomsg printf("create_wiki_link called with type: %s", type)
    if type == 'v' || type == 'V' || type == '^V'
        wiki#link#transform_visual()
    else
        wiki#link#transform_operator(type)
    endif
enddef

# Helper function to create an image link and position cursor
def Create_image_link(type: string)
    var text_to_link = ''
    var new_image_link = ''
    if type == 'v' || type == 'V' || type == '^V'
        var saved_view = winsaveview()
        normal! gv
        text_to_link = getreg('"')
        new_image_link = printf('![%s]()', text_to_link)
        execute "normal! gv\"_c" .. new_image_link
        call winrestview(saved_view)
    else
        var sel_start_pos = getpos("'[")
        var sel_end_pos = getpos("']")
        if sel_start_pos[1] == sel_end_pos[1]
            text_to_link = getline(sel_start_pos[1])[sel_start_pos[2] - 1 : sel_end_pos[2] - 1]
            new_image_link = printf('![%s]()', text_to_link)
            var current_line = getline('.')
            var cursor_col = col('.')
            # Use '\V' to treat pattern literally, and escape for special regex chars.
            # Search around cursor to ensure we replace the correct instance of the word.
            var word_pattern = '\V' .. escape(text_to_link, '\\[]().*~^$')
            var word_start_col = match(current_line, word_pattern, 0, cursor_col - len(text_to_link))
            if word_start_col == -1
                # Fallback if word not found at expected position (e.g., partial word selected by operator)
                # This case should ideally be handled by the 'g@' operator, but as a safeguard:
                # If we can't find the exact word, we might need to insert.
                # For simplicity, we'll just insert at cursor if no clear replacement target.
                # echomsg "Word not found on current line at expected position. Inserting at cursor."
                execute "normal! i" .. new_image_link
                word_start_col = col('.') - len(new_image_link) # Adjust start_col for cursor positioning
            else
                var before = current_line[0 : word_start_col - 1]
                var after = current_line[word_start_col + len(text_to_link) :]
                setline('.', before .. new_image_link .. after)
            endif
        else
            echomsg "Can't create link for multiline text"
            return
        endif
    endif

    # Position cursor inside the parentheses
    var new_line_content = getline(line('.'))
    var new_cursor_col = match(new_line_content, escape(new_image_link, '\\[]().*~^$')) + len(new_image_link) - 1
    # echomsg printf("Positioning cursor at line: %d, col: %d", line('.'), new_cursor_col)
    setpos('.', [0, line('.'), new_cursor_col, 0])
enddef
