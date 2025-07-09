vim9script

import autoload './constants.vim' as constants

# General Utilities & Helpers --------------------------------------------{{{1

# Echoerr ----------------------------------------------------------------{{{2
export def Echoerr(msg: string)
  echohl ErrorMsg | echom $'[markdown_plus] {msg}' | echohl None
enddef

# Echowarn ---------------------------------------------------------------{{{2
export def Echowarn(msg: string)
  echohl WarningMsg | echom $'[markdown_plus] {msg}' | echohl None
enddef

# Syntax and Positional Analysis -----------------------------------------{{{1

# IsInRange --------------------------------------------------------------{{{2
# Multibyte support: All column positions are character-based (1-based)
# Input: Current cursor position (character-based)
# Output: Dict with style as key, value is [start_pos, end_pos] where:
#         - start_pos: [line, char_col] (1-based line, 1-based char column)
#         - end_pos: [line, char_col] (1-based line, 1-based char column)
export def IsInRange(): dict<list<list<number>>>
  # Return a dict like {'markdownCode': [[21, 19], [22, 21]]}.
  # The returned intervals are open.
  #
  # NOTE: Due to that bundled markdown syntax file returns 'markdownItalic' and
  # 'markdownBold' regardless is the delimiters are '_' or '*', we need the
  # StarOrUnderscore() function

  def StarOrUnderscore(text_style: string): string
    var text_style_refined = ''

    var tmp_star = $'constants.TEXT_STYLES_DICT.{text_style}.open_regex'
    const star_delim = eval(tmp_star)
    const pos_star = searchpos(star_delim, 'nbW')

    const tmp_underscore = $'constants.TEXT_STYLES_DICT.{text_style}U.open_regex'
    const underscore_delim = eval(tmp_underscore)
    const pos_underscore = searchpos(underscore_delim, 'nbW')

    if pos_star == [0, 0]
      text_style_refined = text_style .. "U"
    elseif pos_underscore == [0, 0]
      text_style_refined = text_style
    elseif IsGreater(pos_underscore, pos_star)
      text_style_refined = text_style .. "U"
    else
      text_style_refined = text_style
    endif
    return text_style_refined
  enddef

  # Main function start here
  # text_style comes from vim-markdown
  var text_style = synIDattr(synID(line("."), byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name")
  var text_style_origin = text_style
  # echomsg '[IsInRange] text_style: ' .. text_style

  # Delimiter smart detection logic (non-recursive, move cursor to content area if found)
  if text_style =~ 'Delimiter'
    # echomsg '[IsInRange] On Delimiter, try left/right (non-recursive, move cursor)'
    var orig_line = line('.')
    var orig_col = charcol('.')
    var style_base = text_style->substitute('Delimiter$', '', '')
    var open_len = has_key(constants.TEXT_STYLES_DICT, style_base) ? strchars(constants.TEXT_STYLES_DICT[style_base].open_delim) : 2
    var close_len = has_key(constants.TEXT_STYLES_DICT, style_base) ? strchars(constants.TEXT_STYLES_DICT[style_base].close_delim) : 2
    var found = 0
    # Try left within delimiter length
    for i in range(1, open_len)
      if orig_col - i < 1 | continue | endif
      call cursor(orig_line, orig_col - i)
      var left_style = synIDattr(synID(line('.'), charcol('.'), 1), 'name')
      # echomsg '[IsInRange] left_style: ' .. left_style
      if left_style !~ 'Delimiter' && left_style != ''
        found = 1
        break
      endif
    endfor
    # Try right within delimiter length (only if not found on left)
    if !found
      for i in range(1, close_len)
        call cursor(orig_line, orig_col + i)
        var right_style = synIDattr(synID(line('.'), charcol('.'), 1), 'name')
        # echomsg '[IsInRange] right_style: ' .. right_style
        if right_style !~ 'Delimiter' && right_style != ''
          found = 1
          break
        endif
      endfor
    endif
    # If found, cursor is now at content area; do not restore
    if found
      text_style = synIDattr(synID(line('.'), charcol('.'), 1), 'name')
      # echomsg '[IsInRange] text_style within range: ' .. text_style
    else
      # If not found, keep original position and style
      call cursor(orig_line, orig_col)
    endif
  endif

  const text_style_adjusted =
    text_style == 'markdownItalic' || text_style == 'markdownBold'
     ? StarOrUnderscore(synIDattr(synID(line("."), byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name"))
     : synIDattr(synID(line("."), byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name")
  if text_style_adjusted != text_style_origin || text_style_adjusted != text_style
    # echomsg '[IsInRange] text_style_adjusted: ' .. text_style_adjusted
  endif

  var return_val = {}

  if !empty(text_style_adjusted)
      && index(keys(constants.TEXT_STYLES_DICT), text_style_adjusted) != -1

    const saved_curpos = getcursorcharpos()

    # Search start delimiter
    const open_delim =
      eval($'constants.TEXT_STYLES_DICT.{text_style_adjusted}.open_delim')
    var open_delim_pos = searchpos($'\V{open_delim}', 'bW')
    # echomsg '[IsInRange] open_delim: ' ..  open_delim  .. ' start at ' .. string(open_delim_pos)

    var current_style = synIDattr(synID(line("."), byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name")
    # We search for a markdown delimiter or an htmlTag.
    while current_style != $'{text_style}Delimiter'
        && current_style != 'htmlTag'
      && open_delim_pos != [0, 0]
      open_delim_pos = searchpos($'\V{open_delim}', 'bW')
      current_style = synIDattr(synID(line("."), byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name")
    endwhile

    # To avoid infinite loops if some weird delimited text is highlighted
    if open_delim_pos == [0, 0]
      return {}
    endif
    # Convert byte column to character column for open_delim_pos
    var open_delim_char_col = charidx(getline(open_delim_pos[0]), open_delim_pos[1] - 1) + 1
    open_delim_pos[1] = open_delim_char_col + strchars(open_delim)

    # Search end delimiter.
    # The end delimiter may be a blank line, hence
    # things become a bit cumbersome.
    setcursorcharpos(saved_curpos[1 : 2])
    const close_delim =
     eval($'constants.TEXT_STYLES_DICT.{text_style_adjusted}.close_delim')
    var close_delim_pos = searchpos($'\V{close_delim}', 'nW')
    # echomsg '[IsInRange] close_delim: ' .. close_delim .. ' start at ' .. string(close_delim_pos)

    var blank_line_pos = searchpos($'^$', 'nW')
    var first_met = [0, 0] # This variable will no longer be used for cursor positioning directly
    var first_met_char_pos = [0, 0] # Character-based position for cursor and return

    current_style = synIDattr(synID(line("."), byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name")

    while current_style != $'{text_style}Delimiter'
        && current_style != 'htmlEndTag'
        && getline(line('.')) !~ '^$'
      var close_delim_byte_pos = searchpos($'\V{close_delim}', 'nW')
      var blank_line_byte_pos = searchpos($'^$', 'nW')

      var temp_first_met_byte_pos = [0, 0]
      if close_delim_byte_pos == [0, 0]
        temp_first_met_byte_pos = blank_line_byte_pos
      elseif blank_line_byte_pos == [0, 0]
        temp_first_met_byte_pos = close_delim_byte_pos
      else
        temp_first_met_byte_pos = IsLess(close_delim_byte_pos, blank_line_byte_pos)
        ? close_delim_byte_pos
        : blank_line_byte_pos
      endif

      # Convert temp_first_met_byte_pos to character column before setting cursor
      if temp_first_met_byte_pos != [0, 0]
        var temp_first_met_char_col = charidx(getline(temp_first_met_byte_pos[0]), temp_first_met_byte_pos[1] - 1) + 1
        first_met_char_pos = [temp_first_met_byte_pos[0], temp_first_met_char_col]
      else
        first_met_char_pos = [0, 0] # Should not happen if one of them is found
      endif

      setcursorcharpos(first_met_char_pos)
      # echomsg '[DEBUG] Cursor moved to: ' .. string(getcursorcharpos())
      current_style = synIDattr(synID(line("."), byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name")
      # echomsg '[DEBUG] Current style after move: ' .. current_style
    endwhile
    # echomsg '[IsInRange] first_met_char_pos: ' .. string(first_met_char_pos)

    # If we hit a blank line, then we take the previous line and last column,
    # to keep consistency in returning open-intervals
    if getline(line('.')) =~ '^$'
      first_met_char_pos[0] = first_met_char_pos[0] - 1
      first_met_char_pos[1] = strchars(getline(first_met_char_pos[0]))
    else
      first_met_char_pos[1] = first_met_char_pos[1] - 1
    endif
    # echomsg '[IsInRange] first_met: ' .. string(first_met)

    setcursorcharpos(saved_curpos[1 : 2])
    return_val =  {[text_style_adjusted]: [open_delim_pos, first_met_char_pos]}
    # echomsg '[IsInRange] content style and range ' .. string(return_val)
  else
    # echomsg '[IsInRange] not in range.'
  endif

  return return_val
enddef
