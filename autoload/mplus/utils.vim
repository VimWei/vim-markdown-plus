vim9script

import autoload './constants.vim' as constants
import autoload './links.vim' as links

# Text Styling and Surrounding -------------------------------------------{{{1

# ToggleSurround ---------------------------------------------------------{{{2
export def ToggleSurround(style: string, type: string = '')
  var range_info = IsInRange()
  echomsg '[ToggleSurround] style: ' .. style
  echomsg '[ToggleSurround] range_info: ' .. string(range_info)
  if !empty(range_info) && keys(range_info)[0] == style
    echomsg '[ToggleSurround] Will call RemoveSurrounding'
    RemoveSurrounding(range_info)
  else
    echomsg '[ToggleSurround] Will call SurroundSmart'
    SurroundSmart(style, type)
  endif
enddef

# SurroundSimple ----------------------------------------------------------{{{2
export def SurroundSimple(style: string, type: string = '')

  if getcharpos("'[") == getcharpos("']")
    return
  endif

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
export def SurroundSmart(style: string, type: string = '')
  # It tries to preserve the style.
  # In general, you may want to pass constant.TEXT_STYLES_DICT as a parameter.

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
    return overwritten
  enddef

  if getcharpos("'[") == getcharpos("']")
    return
  endif

  if index(keys(constants.TEXT_STYLES_DICT), style) == -1
    Echoerr($'Style "{style}" not found in dict')
    return
  endif

  var open_delim = constants.TEXT_STYLES_DICT[style].open_delim
  var open_regex = constants.TEXT_STYLES_DICT[style].open_regex

  var close_delim = constants.TEXT_STYLES_DICT[style].close_delim
  var close_regex = constants.TEXT_STYLES_DICT[style].close_regex

  # line and column of point A
  var lA = line("'[")
  var cA = type == 'line' ? 1 : charcol("'[")

  # line and column of point B
  var lB = line("']")
  var cB = type == 'line' ? strchars(getline(lB)) : charcol("']")

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
  var found_interval = IsInRange()
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
  found_interval = IsInRange()
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

# RemoveSurrounding ------------------------------------------------------{{{2
export def RemoveSurrounding(range_info: dict<list<list<number>>> = {})
    const style_interval = empty(range_info) ? IsInRange() : range_info
    echomsg '[RemoveSurrounding] style_interval: ' .. string(style_interval)
    if !empty(style_interval)
      const style = keys(style_interval)[0]
      const interval = values(style_interval)[0]

      # Remove left delimiter
      const lA = interval[0][0]
      const cA = interval[0][1]
      const lineA = getline(lA)
      var newline = strcharpart(lineA, 0,
              \ cA - 1 - len(constants.TEXT_STYLES_DICT[style].open_delim))
              \ .. strcharpart(lineA, cA - 1)
      setline(lA, newline)

      # Remove right delimiter
      const lB = interval[1][0]
      const cB = interval[1][1]
      echomsg '[RemoveSurrounding] style: ' .. style
      echomsg '[RemoveSurrounding] lA: ' .. lA .. ', cA: ' .. cA .. ', lB: ' .. lB .. ', cB: ' .. cB
      # 防御性检查，避免非法行号
      if lA <= 0 || lB <= 0
        Echowarn('RemoveSurrounding: invalid line number')
        return
      endif

      # Check if you hit a delimiter or a blank line OR if you hit a delimiter
      # but you also have a blank like
      # If you have open intervals (as we do), then cB < lenght_of_line, If
      # not, then don't do anything. This behavior is compliant with
      # vim-surround
      const open_len = strchars(constants.TEXT_STYLES_DICT[style].open_delim)
      const close_len = strchars(constants.TEXT_STYLES_DICT[style].close_delim)
      if lA == lB
        const lineA = getline(lA)
        echomsg '[RemoveSurrounding] lineA(before): ' .. lineA
        echomsg '[RemoveSurrounding] cA: ' .. cA .. ', cB: ' .. cB .. ', open_len: ' .. open_len .. ', close_len: ' .. close_len
        echomsg '[RemoveSurrounding] content: ' .. strcharpart(lineA, cA - 1, cB - cA - 1)
        var newline = strcharpart(lineA, 0, cA - 1 - open_len)
              .. strcharpart(lineA, cA - 1, cB - cA - 1)
              .. strcharpart(lineA, cB + close_len - 1)
        echomsg '[RemoveSurrounding] lineA(after): ' .. newline
        setline(lA, newline)
      else
        # You hit the end of paragraph
        const lineA = getline(lA)
        echomsg '[RemoveSurrounding] lineA(before): ' .. lineA
        var newline = strcharpart(lineA, 0,
                \ cA - 1 - strchars(constants.TEXT_STYLES_DICT[style].open_delim))
                \ .. strcharpart(lineA, cA - 1)
        echomsg '[RemoveSurrounding] lineA(after): ' .. newline
        setline(lA, newline)
        # Remove right delimiter
        var cB2 = cB
        const lineB = getline(lB)
        echomsg '[RemoveSurrounding] lineB(before): ' .. lineB
        if  cB2 < strchars(lineB)
          newline = strcharpart(lineB, 0, cB2)
                \ .. strcharpart(lineB,
                  \ cB2 + strchars(constants.TEXT_STYLES_DICT[style].close_delim))
          echomsg '[RemoveSurrounding] lineB(after): ' .. newline
        else
          newline = lineB
          echomsg '[RemoveSurrounding] lineB(after, unchanged): ' .. newline
        endif
        setline(lB, newline)
      endif
      setline(lB, newline)
    endif
enddef

# RemoveAll --------------------------------------------------------------{{{2
export def RemoveAll()
  # TODO could be refactored to increase speed, but it may not be necessary
  const range_info = IsInRange()
  const prop_info = IsOnProp()
  const syn_info = synIDattr(synID(line("."), col("."), 1), "name")
  const is_quote_block = getline('.') =~ '^>\s'

  # If on plain text, do nothing, just execute a normal! <BS>
  if empty(range_info) && empty(prop_info)
        && syn_info != 'markdownCodeBlock' && !is_quote_block
    exe "norm! \<BS>"
    return
  endif

  # Start removing the text props
  if !empty(prop_info)
    prop_remove({'id': prop_info.id, 'all': 0})
    return
  endif

  # Check markdownCodeBlocks
  if syn_info == 'markdownCodeBlock'
    UnsetBlock(syn_info)
    return
  endif

  # Text styles removal setup
  if !empty(range_info)
    const target = keys(range_info)[0]
    var text_styles = copy(constants.TEXT_STYLES_DICT)
    unlet text_styles['markdownLinkText']

    if index(keys(text_styles), target) != -1
      RemoveSurrounding(range_info)
    elseif target == 'markdownLinkText'
      links.RemoveLink()
    endif
    return
  endif

  if is_quote_block
    UnsetQuoteBlock()
  endif
enddef

# Block-Level Manipulation -----------------------------------------------{{{1

# SetQuoteBlock ----------------------------------------------------------{{{2
export def SetQuoteBlock(type: string = '')

  # We set cA=1 and cB = len(geline(B)) so we pretend that we are working
  # always line-wise
  var lA = line("'[")
  var lB = line("']")

  for line_nr in range(lA, lB)
    setline(line_nr, $'> {getline(line_nr)}')
  endfor
enddef

# UnsetQuoteBlock --------------------------------------------------------{{{2
export def UnsetQuoteBlock()
  const open_regex = values(constants.QUOTEBLOCK_OPEN_DICT)[0]
  # Line that starts with everything but '\s*>'-ish
  const close_regex = values(constants.QUOTEBLOCK_CLOSE_DICT)[0]

  const saved_curpos = getcurpos()
  var line_nr = saved_curpos[1]
  var line_content = getline(line_nr)

  if line_content !~ open_regex
    return
  endif

  # Moving up
  while line_content !~ close_regex && line_nr > 0
    setline(line_nr, line_content->substitute('>\s', '', ''))
    line_nr -= 1
    line_content = getline(line_nr)
  endwhile

  # Moving down
  setpos('.', saved_curpos)
  line_nr = line('.') + 1
  line_content = getline(line_nr)
  while line_content !~ close_regex && line_nr <= line('$')
    setline(line_nr, line_content->substitute('>\s', '', ''))
    line_nr += 1
    line_content = getline(line_nr)
  endwhile
  setpos('.', saved_curpos)
enddef

# Syntax and Positional Analysis -----------------------------------------{{{1

# IsInRange --------------------------------------------------------------{{{2
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
  var text_style = synIDattr(synID(line('.'), col('.'), 1), 'name')

  # Delimiter smart detection logic (non-recursive, move cursor to content area if found)
  if text_style =~ 'Delimiter'
    echomsg '[IsInRange] On Delimiter, try left/right (non-recursive, move cursor)'
    var orig_line = line('.')
    var orig_col = col('.')
    var style_base = text_style->substitute('Delimiter$', '', '')
    var open_len = has_key(constants.TEXT_STYLES_DICT, style_base) ? strchars(constants.TEXT_STYLES_DICT[style_base].open_delim) : 2
    var close_len = has_key(constants.TEXT_STYLES_DICT, style_base) ? strchars(constants.TEXT_STYLES_DICT[style_base].close_delim) : 2
    var found = 0
    # Try left within delimiter length
    for i in range(1, open_len)
      if orig_col - i < 1 | continue | endif
      call cursor(orig_line, orig_col - i)
      var left_style = synIDattr(synID(line('.'), col('.'), 1), 'name')
      echomsg '[IsInRange] left_style: ' .. left_style
      if left_style !~ 'Delimiter' && left_style != ''
        found = 1
        break
      endif
    endfor
    # Try right within delimiter length (only if not found on left)
    if !found
      for i in range(1, close_len)
        call cursor(orig_line, orig_col + i)
        var right_style = synIDattr(synID(line('.'), col('.'), 1), 'name')
        echomsg '[IsInRange] right_style: ' .. right_style
        if right_style !~ 'Delimiter' && right_style != ''
          found = 1
          break
        endif
      endfor
    endif
    # If found, cursor is now at content area; do not restore
    if found
      text_style = synIDattr(synID(line('.'), col('.'), 1), 'name')
    else
      # If not found, keep original position and style
      call cursor(orig_line, orig_col)
    endif
  endif

  const text_style_adjusted =
    text_style == 'markdownItalic' || text_style == 'markdownBold'
     ? StarOrUnderscore(text_style)
     : text_style
  var return_val = {}

  echomsg '[IsInRange] text_style: ' .. text_style
  echomsg '[IsInRange] text_style_adjusted: ' .. text_style_adjusted
  if !empty(text_style_adjusted)
      && index(keys(constants.TEXT_STYLES_DICT), text_style_adjusted) != -1

    const saved_curpos = getcursorcharpos()

    # Search start delimiter
    const open_delim =
      eval($'constants.TEXT_STYLES_DICT.{text_style_adjusted}.open_delim')

    var open_delim_pos = searchpos($'\V{open_delim}', 'bW')
    var current_style = synIDattr(synID(line("."), col("."), 1), "name")
    # We search for a markdown delimiter or an htmlTag.
    while current_style != $'{text_style}Delimiter'
        && current_style != 'htmlTag'
      && open_delim_pos != [0, 0]
      open_delim_pos = searchpos($'\V{open_delim}', 'bW')
      current_style = synIDattr(synID(line("."), col("."), 1), "name")
    endwhile

    # To avoid infinite loops if some weird delimited text is highlighted
    if open_delim_pos == [0, 0]
      return {}
    endif
    open_delim_pos[1] += len(open_delim)

    # Search end delimiter.
    # The end delimiter may be a blank line, hence
    # things become a bit cumbersome.
    setcursorcharpos(saved_curpos[1 : 2])
    const close_delim =
     eval($'constants.TEXT_STYLES_DICT.{text_style_adjusted}.close_delim')
    var close_delim_pos = searchpos($'\V{close_delim}', 'nW')
    var blank_line_pos = searchpos($'^$', 'nW')
    var first_met = [0, 0]
    current_style = synIDattr(synID(line('.'), col('.'), 1), 'name')

    while current_style != $'{text_style}Delimiter'
        && current_style != 'htmlEndTag'
        && getline(line('.')) !~ '^$'
      close_delim_pos = searchpos($'\V{close_delim}', 'nW')
      blank_line_pos = searchpos($'^$', 'nW')
      if close_delim_pos == [0, 0]
        first_met = blank_line_pos
      elseif blank_line_pos == [0, 0]
        first_met = close_delim_pos
      else
        first_met = IsLess(close_delim_pos, blank_line_pos)
        ? close_delim_pos
        : blank_line_pos
      endif
      setcursorcharpos(first_met)
      current_style = synIDattr(synID(line('.'), col('.'), 1), 'name')
    endwhile

    # If we hit a blank line, then we take the previous line and last column,
    # to keep consistency in returning open-intervals
    if getline(line('.')) =~ '^$'
      first_met[0] = first_met[0] - 1
      first_met[1] = strchars(getline(first_met[0]))
    endif

    setcursorcharpos(saved_curpos[1 : 2])
    const open_len = strchars(open_delim)
    const close_len = strchars(close_delim)
    var content_start = open_delim_pos[1] + open_len
    var content_end = first_met[1] - 1
    return_val =  {[text_style_adjusted]: [[open_delim_pos[0], content_start], [first_met[0], content_end]]}
    echomsg '[IsInRange] open_delim: ' .. open_delim
    echomsg '[IsInRange] open_delim_pos: ' .. string(open_delim_pos)
    echomsg '[IsInRange] close_delim: ' .. close_delim
    echomsg '[IsInRange] close_delim_pos: ' .. string(close_delim_pos)
    echomsg '[IsInRange] first_met: ' .. string(first_met)
    echomsg '[IsInRange] return_val: ' .. string(return_val)
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

# IsOnProp ---------------------------------------------------------------{{{2
export def IsOnProp(): dict<any>
  var prop = prop_find({type: prop_name, 'col': col('.')}, 'b')
  if has_key(prop, 'id')
    if line('.') != prop.lnum || col('.') > prop.col + prop.length
      prop = {}
    endif
  endif
  return prop
enddef
