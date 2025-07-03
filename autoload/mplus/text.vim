vim9script

import autoload './constants.vim' as constants
import autoload './utils.vim' as utils

# ToggleSurround ---------------------------------------------------------{{{1
export def ToggleSurround(style: string, type: string = '')
    # echomsg '```echomsg ------------------------------------'
    # echomsg '[ToggleSurround] start: ' .. style
    if style == 'markdownRemoveAll'
        RemoveAll(style, type)
        return
    endif
    # echomsg '[ToggleSurround] check cursor IsInRange ...'
    var range_info = utils.IsInRange()
    if !empty(range_info) && keys(range_info)[0] == style
        # echomsg '[ToggleSurround] Will call RemoveSurrounding'
        RemoveSurrounding(range_info)
    else
        # echomsg '[ToggleSurround] Will call SurroundSmart'
        SurroundSmart(style, type)
    endif
    # echomsg '```'
    # call Redir#redir('messages', 0, 0, 0)
enddef

# Surround ---------------------------------------------------------------{{{1
# SurroundSimple ---------------------------------------------------------{{{2
# Multibyte support: All line/column positions are 1-based character indices
# Input: lA, cA, lB, cB (1-based, character)
# Output: setline 操作均基于字符索引
export def SurroundSimple(style: string, type: string = '')

    # if getcharpos("'[") == getcharpos("']")
    #   return
    # endif

    var open_delim = constants.TEXT_STYLES_DICT[style].open_delim
    var close_delim = constants.TEXT_STYLES_DICT[style].close_delim

    # line and column of point A
    var lA = line("'[")
    var cA = charcol("'[")

    # line and column of point B
    var lB = line("']")
    var cB = charcol("']")

    var toA = strcharpart(getline(lA), 0, cA - 1) .. open_delim
    var fromB = close_delim .. strcharpart(getline(lB), cB)

    # If on the same line
    if lA == lB
        # Overwrite everything that is in the middle
        var A_to_B = strcharpart(getline(lA), cA - 1, cB - cA + 1)
        setline(lA, toA .. A_to_B .. fromB)
    else
        var lineA = toA .. strcharpart(getline(lA), cA - 1)
        setline(lA, lineA)
        var lineB = strcharpart(getline(lB), 0, cB - 1) .. fromB
        setline(lB, lineB)
        var ii = 1
        # Fix intermediate lines
        while lA + ii < lB
            setline(lA + ii, getline(lA + ii))
            ii += 1
        endwhile
    endif
enddef

# SurroundSmart ----------------------------------------------------------{{{2
# Multibyte support: All line/column positions are 1-based character indices
# Input: lA, cA, lB, cB (1-based, character)
# Output: setline 操作均基于字符索引
export def SurroundSmart(style: string, type: string = '')
    # It tries to preserve the style.
    # In general, you may want to pass constant.TEXT_STYLES_DICT as a parameter.

    # if getcharpos("'[") == getcharpos("']")
    #   return
    # endif

    if index(keys(constants.TEXT_STYLES_DICT), style) == -1
        utils.Echoerr($'Style "{style}" not found in dict')
        return
    endif

    var open_delim = constants.TEXT_STYLES_DICT[style].open_delim
    var open_regex = constants.TEXT_STYLES_DICT[style].open_regex

    var close_delim = constants.TEXT_STYLES_DICT[style].close_delim
    var close_regex = constants.TEXT_STYLES_DICT[style].close_regex

    # line and column of point A
    var lA = line("'[")
    var cA = type == 'line' ? 1 : charcol("'[")
    # echomsg '[SurroundSmart] line and column of point A: [' .. lA .. ',' .. cA .. ']'

    # line and column of point B
    var lB = line("']")
    var cB = type == 'line' ? strchars(getline(lB)) : charcol("']")
    # echomsg '[SurroundSmart] line and column of point B: [' .. lB .. ',' .. cB .. ']'

    # -------- SMART DELIMITERS BEGIN ---------------------------
    # We check conditions like the following and we adjust the style
    # delimiters
    # We assume that the existing style ranges are (C,D) and (E,F) and we want
    # to place (A,B) as in the picture
    #
    # -E-------A------------
    # ------------F---------
    # ------------C------B--
    # --------D-------------
    #
    # We want to get:
    #
    # -E------FA------------
    # ----------------------
    # ------------------BC--
    # --------D-------------
    #
    # so that all the styles are visible

    # Check if A falls in an existing interval
    cursor(lA, cA)
    var old_right_delimiter = ''
    # echomsg '[SurroundSmart] check point A IsInRange ...'
    var found_interval = utils.IsInRange()
    if !empty(found_interval)
        var found_style = keys(found_interval)[0]
        old_right_delimiter = constants.TEXT_STYLES_DICT[found_style].open_delim
    endif

    # Try to preserve overlapping ranges by moving the delimiters.
    # For example. If we have the pairs (C, D) and (E,F) as it follows:
    # ------C-------D------E------F
    #  and we want to add (A, B) as it follows
    # ------C---A---D-----E--B---F
    #  then the results becomes a mess. The idea is to move D before A and E
    #  after E, thus obtaining:
    # ------C--DA-----------BE----F
    #
    # TODO:
    # If you don't want to try to automatically adjust existing ranges, then
    # remove 'old_right_delimiter' and 'old_left_limiter' from what follows,
    # AND don't remove anything between A and B
    #
    # TODO: the following is specifically designed for markdown, so if you use
    # for other languages, you may need to modify it!
    #
    var toA = ''
    if !empty(found_interval) && old_right_delimiter != open_delim
        toA = strcharpart(getline(lA), 0, cA - 1)->substitute('\s*$', '', '')
            .. $'{old_right_delimiter} {open_delim}'
    elseif !empty(found_interval) && old_right_delimiter == open_delim
        # If the found interval is a text style equal to the one you want to set,
        # i.e. you would end up in adjacent delimiters like ** ** => Remove both
        toA = strcharpart(getline(lA), 0, cA - 1)
    else
        # Force space
        toA = strcharpart(getline(lA), 0, cA - 1) .. open_delim
    endif

    # Check if B falls in an existing interval
    cursor(lB, cB)
    var old_left_delimiter = ''

    # echomsg '[SurroundSmart] check point B IsInRange ...'
    found_interval = utils.IsInRange()
    if !empty(found_interval)
        var found_style = keys(found_interval)[0]
        old_left_delimiter = constants.TEXT_STYLES_DICT[found_style].close_delim
    endif

    var fromB = ''
    if !empty(found_interval) && old_left_delimiter != close_delim
        # Move old_left_delimiter "outside"
        fromB = $'{close_delim} {old_left_delimiter}'
            .. strcharpart(getline(lB), cB)->substitute('^\s*', '', '')
    elseif !empty(found_interval) && old_left_delimiter == close_delim
        fromB = strcharpart(getline(lB), cB)
    else
        fromB = close_delim .. strcharpart(getline(lB), cB)
    endif
    # echomsg '[SurroundSmart] SMART DELIMITERS processed.'
    # ------- SMART DELIMITERS PART END -----------
    # We have compute the partial strings until A and the partial string that
    # leaves B. Existing delimiters are set.
    # Next, we have to adjust the text between A and B, by removing all the
    # possible delimiters left between them.

    # If on the same line
    if lA == lB
        # Overwrite everything that is in the middle
        var A_to_B = ''
        A_to_B = strcharpart(getline(lA), cA - 1, cB - cA + 1)

        # Overwrite existing styles in the middle by removing old delimiters
        if style != 'markdownCode'
            A_to_B = RemoveDelimiters(A_to_B)
        endif
        # echom $'toA: ' .. toA
        # echom $'fromB: ' .. fromB
        # echom $'A_to_B:' .. A_to_B
        # echom '----------\n'

        # Set the whole line
        setline(lA, toA .. A_to_B .. fromB)

    else
        # Set line A
        var afterA = strcharpart(getline(lA), cA - 1)

        if style != 'markdownCode'
            afterA = RemoveDelimiters(afterA)
        endif

        var lineA = toA .. afterA
        setline(lA, lineA)

        # Set line B
        var beforeB = strcharpart(getline(lB), 0, cB)

        if style != 'markdownCode'
            beforeB = RemoveDelimiters(beforeB)
        endif

        var lineB = beforeB .. fromB
        setline(lB, lineB)

        # Fix intermediate lines
        var ii = 1
        while lA + ii < lB
            var middleline = getline(lA + ii)

            if style != 'markdownCode'
                middleline = RemoveDelimiters(middleline)
            endif

            setline(lA + ii, middleline)
            ii += 1
        endwhile
    endif
enddef

# Remove -----------------------------------------------------------------{{{1
# RemoveDelimiters -------------------------------------------------------{{{2
def RemoveDelimiters(to_overwrite: string): string
    # Used for removing all the delimiters between A and B.

    var overwritten = to_overwrite

    # This is needed to remove all existing text-styles between A and B, i.e. we
    # want to override existing styles.
    # Note that we don't want to remove links between A and B
    const styles_to_remove = keys(constants.TEXT_STYLES_DICT)
        ->filter("v:val !~ '\\v(markdownLinkText)'")

    for k in styles_to_remove
        # Remove existing open delimiters
        var regex = constants.TEXT_STYLES_DICT[k].open_regex
        var to_remove = constants.TEXT_STYLES_DICT[k].open_delim
        overwritten = overwritten
            ->substitute(regex, (m) => substitute(m[0], $'\V{to_remove}', '', 'g'), 'g')

        # Remove existing close delimiters
        regex = constants.TEXT_STYLES_DICT[k].close_regex
        to_remove = constants.TEXT_STYLES_DICT[k].close_delim
        overwritten = overwritten
            ->substitute(regex, (m) => substitute(m[0], $'\V{to_remove}', '', 'g'), 'g')
    endfor
    # echomsg '[SurroundSmart] Remove all existing text-styles between A and B'
    return overwritten
enddef

# RemoveSurrounding ------------------------------------------------------{{{2
# Multibyte support: All line/column positions are 1-based character indices
# Input: interval: [[lA, cA], [lB, cB]] (1-based, character)
# Output: setline 操作均基于字符索引
export def RemoveSurrounding(range_info: dict<list<list<number>>> = {})
    const style_interval = empty(range_info) ? utils.IsInRange() : range_info
    # echomsg '[RemoveSurrounding] style_interval: ' .. string(style_interval)
    if !empty(style_interval)
        const style = keys(style_interval)[0]
        const interval = values(style_interval)[0]
        # echomsg '[RemoveSurrounding] style: ' .. style

        # Remove left delimiter
        const lA = interval[0][0]
        const cA = interval[0][1]
        # echomsg '[RemoveSurrounding] Range starts at: [' .. lA .. ',' .. cA .. ']'

        const lineA = getline(lA)
        # echomsg '[RemoveSurrounding] lineA(before): ' .. lineA

        var newline = strcharpart(lineA, 0,
                    \ cA - 1 - strchars(constants.TEXT_STYLES_DICT[style].open_delim))
                    \ .. strcharpart(lineA, cA - 1)
        setline(lA, newline)
        # echomsg '[RemoveSurrounding] lineA(after): ' .. getline(lA)

        # Remove right delimiter
        const lB = interval[1][0]
        var cB = interval[1][1]
        # echomsg '[RemoveSurrounding] Range ends at: [' .. lB .. ',' .. cB .. ']'

        # Update cB.
        # If lA == lB, then The value of cB may no longer be valid since
        # we shortened the line
        if lA == lB
            cB = cB - strchars(constants.TEXT_STYLES_DICT[style].open_delim)
        endif

        # Check if you hit a delimiter or a blank line OR if you hit a delimiter
        # but you also have a blank like
        # If you have open intervals (as we do), then cB < lenght_of_line, If
        # not, then don't do anything. This behavior is compliant with
        # vim-surround
        const lineB = getline(lB)
        # echomsg '[RemoveSurrounding] lineB(before): ' .. lineB

        if  cB < strchars(lineB)
            # You have delimters
            newline = strcharpart(lineB, 0, cB)
                        \ .. strcharpart(lineB,
                        \ cB + strchars(constants.TEXT_STYLES_DICT[style].close_delim))
        else
            # You hit the end of paragraph
            newline = lineB
        endif
        setline(lB, newline)
        # echomsg '[RemoveSurrounding] lineB(after): ' .. getline(lB)
    endif
enddef

# RemoveAll --------------------------------------------------------------{{{2
export def RemoveAll(style: string, type: string = '')
    # line and column of point A
    var lA = line("'[")
    var cA = type == 'line' ? 1 : charcol("'[")
    # echomsg '[RemoveAll] line and column of point A: [' .. lA .. ',' .. cA .. ']'

    # line and column of point B
    var lB = line("']")
    var cB = type == 'line' ? strchars(getline(lB)) : charcol("']")
    # echomsg '[RemoveAll] line and column of point B: [' .. lB .. ',' .. cB .. ']'

    # -------- SMART DELIMITERS BEGIN ---------------------------
    # Check if A falls in an existing interval
    cursor(lA, cA)
    var cA_text_style = synIDattr(synID(line("."), byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name")
    var open_delim = ''
    var old_right_delimiter = ''
    # echomsg '[RemoveAll] check point A IsInRange ...'
    var found_interval = utils.IsInRange()
    if !empty(found_interval)
        var found_style = keys(found_interval)[0]
        old_right_delimiter = constants.TEXT_STYLES_DICT[found_style].open_delim
    endif
    if cA_text_style =~ 'Delimiter'
        open_delim = old_right_delimiter
    endif

    var toA = ''
    if !empty(found_interval) && old_right_delimiter != open_delim
        toA = strcharpart(getline(lA), 0, cA - 1)->substitute('\s*$', '', '')
            .. $'{old_right_delimiter}'
    elseif !empty(found_interval) && old_right_delimiter == open_delim
        toA = strcharpart(getline(lA), 0, cA - 1)
    else
        # Force space
        toA = strcharpart(getline(lA), 0, cA - 1) .. open_delim
    endif

    # Check if B falls in an existing interval
    cursor(lB, cB)
    var cB_text_style = synIDattr(synID(line("."), byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name")
    var close_delim = ''
    var old_left_delimiter = ''
    # echomsg '[RemoveAll] check point B IsInRange ...'
    found_interval = utils.IsInRange()
    if !empty(found_interval)
        var found_style = keys(found_interval)[0]
        old_left_delimiter = constants.TEXT_STYLES_DICT[found_style].close_delim
    endif
    if cB_text_style =~ 'Delimiter'
        close_delim = old_left_delimiter
    endif

    var fromB = ''
    if !empty(found_interval) && old_left_delimiter != close_delim
        # Move old_left_delimiter "outside"
        fromB = $'{old_left_delimiter}'
            .. strcharpart(getline(lB), cB)->substitute('^\s*', '', '')
    elseif !empty(found_interval) && old_left_delimiter == close_delim
        fromB = strcharpart(getline(lB), cB)
    else
        fromB = strcharpart(getline(lB), cB)
    endif
    # echomsg '[RemoveAll] SMART DELIMITERS processed.'
    # ------- SMART DELIMITERS PART END -----------

    # If on the same line
    if lA == lB
        # Overwrite everything that is in the middle
        var A_to_B = ''
        A_to_B = strcharpart(getline(lA), cA - 1, cB - cA + 1)

        # Overwrite existing styles in the middle by removing old delimiters
        if style != 'markdownCode'
            A_to_B = RemoveDelimiters(A_to_B)
        endif
        # echom $'toA: ' .. toA
        # echom $'fromB: ' .. fromB
        # echom $'A_to_B:' .. A_to_B
        # echom '----------\n'

        # Set the whole line
        setline(lA, toA .. A_to_B .. fromB)

    else
        # Set line A
        var afterA = strcharpart(getline(lA), cA - 1)

        if style != 'markdownCode'
            afterA = RemoveDelimiters(afterA)
        endif

        var lineA = toA .. afterA
        setline(lA, lineA)

        # Set line B
        var beforeB = strcharpart(getline(lB), 0, cB)

        if style != 'markdownCode'
            beforeB = RemoveDelimiters(beforeB)
        endif

        var lineB = beforeB .. fromB
        setline(lB, lineB)

        # Fix intermediate lines
        var ii = 1
        while lA + ii < lB
            var middleline = getline(lA + ii)

            if style != 'markdownCode'
                middleline = RemoveDelimiters(middleline)
            endif

            setline(lA + ii, middleline)
            ii += 1
        endwhile
    endif
enddef
