vim9script

import autoload './constants.vim' as constants

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
  echomsg '[IsInRange] text_style: ' .. text_style

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
    echomsg '[IsInRange] text_style_adjusted: ' .. text_style_adjusted
  endif

  var return_val = {}

  if !empty(text_style_adjusted)
      && index(keys(constants.TEXT_STYLES_DICT), text_style_adjusted) != -1

    const saved_curpos = getcursorcharpos()

    # Search start delimiter
    const open_delim =
      eval($'constants.TEXT_STYLES_DICT.{text_style_adjusted}.open_delim')
    var open_delim_pos = searchpos($'\V{open_delim}', 'bW')
    echomsg '[IsInRange] open_delim: ' ..  open_delim  .. ' start at ' .. string(open_delim_pos)

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
    echomsg '[IsInRange] close_delim: ' .. close_delim .. ' start at ' .. string(close_delim_pos)

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
      echomsg '[DEBUG] Cursor moved to: ' .. string(getcursorcharpos())
      current_style = synIDattr(synID(line("."), byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name")
      echomsg '[DEBUG] Current style after move: ' .. current_style
    endwhile
    echomsg '[IsInRange] first_met_char_pos: ' .. string(first_met_char_pos)

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
    echomsg '[IsInRange] content style and range ' .. string(return_val)
  else
    echomsg '[IsInRange] not in range.'
  endif

  return return_val
enddef

# IsLess -----------------------------------------------------------------{{{2
export def IsLess(l1: list<number>, l2: list<number>): bool
  # Lexicographic comparison on common prefix, i.e.for two vectors in N^n and
  # N^m you compare their projections onto the smaller subspace.

  var min_length = min([len(l1), len(l2)])
  var result = false

  for ii in range(min_length)
    if l1[ii] < l2[ii]
      result = true
      break
    elseif l1[ii] > l2[ii]
      result = false
      break
    endif
  endfor
  return result
enddef

# IsGreater --------------------------------------------------------------{{{2
export def IsGreater(l1: list<number>, l2: list<number>): bool
  # Lexicographic comparison on common prefix, i.e.for two vectors in N^n and
  # N^m you compare their projections onto the smaller subspace.

  var min_length = min([len(l1), len(l2)])
  var result = false

  for ii in range(min_length)
    if l1[ii] > l2[ii]
      result = true
      break
    elseif l1[ii] < l2[ii]
      result = false
      break
    endif
  endfor
  return result
enddef

# IsEqual ----------------------------------------------------------------{{{2
export def IsEqual(l1: list<number>, l2: list<number>): bool
  var min_length = min([len(l1), len(l2)])
  return l1[: min_length - 1] == l2[: min_length - 1]
enddef

# IsBetweenMarks ---------------------------------------------------------{{{2
export def IsBetweenMarks(A: string, B: string): bool
    var cursor_pos = getpos(".")
    var A_pos = getcharpos(A)
    var B_pos = getcharpos(B)

    if IsGreater(A_pos, B_pos)
      var tmp = B_pos
      B_pos = A_pos
      A_pos = tmp
    endif

    # Check 'A_pos <= cursor_pos <= B_pos'
    var result = (IsGreater(cursor_pos, A_pos) || IsEqual(cursor_pos, A_pos))
      && (IsGreater(B_pos, cursor_pos) || IsEqual(B_pos, cursor_pos))

    return result
enddef

# GetTextObject ----------------------------------------------------------{{{2
export def GetTextObject(textobject: string): dict<any>
  # You pass a text object like 'iw' and it returns the text
  # associated to it along with the start and end positions.
  #
  # Note that when you yank some text, the registers '[' and ']' are set, so
  # after call this function, you can retrieve start and end position of the
  # text-object by looking at such marks.
  #
  # The function also work with motions.

  # Backup the content of register t (arbitrary choice, YMMV) and marks
  var oldreg = getreg("t")
  var saved_A = getcharpos("'[")
  var saved_B = getcharpos("']")
  # silently yank the text covered by whatever text object
  # was given as argument into register t. Yank also set marks '[ and ']
  noautocmd execute 'silent normal "ty' .. textobject

  var text = getreg("t")
  var start_pos = getcharpos("'[")
  var end_pos = getcharpos("']")

  # restore register t and marks
  setreg("t", oldreg)
  setcharpos("'[", saved_A)
  setcharpos("']", saved_B)

  return {text: text, start: start_pos, end: end_pos}
enddef

# General Utilities & Helpers --------------------------------------------{{{1

# Echoerr ----------------------------------------------------------------{{{2
export def Echoerr(msg: string)
  echohl ErrorMsg | echom $'[markdown_plus] {msg}' | echohl None
enddef

# Echowarn ---------------------------------------------------------------{{{2
export def Echowarn(msg: string)
  echohl WarningMsg | echom $'[markdown_plus] {msg}' | echohl None
enddef

# FormatWithoutMoving ----------------------------------------------------{{{2
export def FormatWithoutMoving(a: number = 0, b: number = 0)
  # To be used for formatting through autocmds
  var view = winsaveview()
  if a == 0 && b == 0
    silent exe $":norm! gggqG"
  else
    var interval = b - a + 1
    silent exe $":norm! {a}gg{interval}gqq"
  endif

  if v:shell_error != 0
    undo
    Echoerr($"'{&l:formatprg->matchstr('^\s*\S*')}' returned errors.")
  else
    # Display format command
    redraw
    if !empty(&l:formatprg)
      echo $'{&l:formatprg}'
    else
      Echowarn("'formatprg' is empty. Using default formatter.")
    endif
  endif
  winrestview(view)
enddef

# KeysFromValue ----------------------------------------------------------{{{2
export def KeysFromValue(dict: dict<string>, target_value: string): list<string>
 # Given a value, return all the keys associated to it
 return keys(filter(copy(dict), $'v:val == "{escape(target_value, "\\")}"'))
enddef

# IsOnProp ---------------------------------------------------------------{{{2
# Multibyte support: Uses charcol() for character-based column positions
export def IsOnProp(): dict<any>
  var prop = prop_find({type: prop_name, 'col': charcol('.')}, 'b')
  if has_key(prop, 'id')
    if line('.') != prop.lnum || charcol('.') > prop.col + prop.length
      prop = {}
    endif
  endif
  return prop
enddef
