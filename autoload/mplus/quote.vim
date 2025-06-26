vim9script

import autoload './constants.vim' as constants

# SetQuoteBlock ----------------------------------------------------------{{{1
export def SetQuoteBlock(type: string = '')

  # We set cA=1 and cB = len(geline(B)) so we pretend that we are working
  # always line-wise
  var lA = line("'[")
  var lB = line("']")

  for line_nr in range(lA, lB)
    setline(line_nr, $'> {getline(line_nr)}')
  endfor
enddef

# UnsetQuoteBlock --------------------------------------------------------{{{1
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
