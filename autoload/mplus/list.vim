vim9script

# list_symbols and pattern -----------------------------------------------{{{1

var list_symbols = [
    \ '*',
    \ '-',
    \ '+',
    \ '1.',
    \ 'a.',
    \ 'A.',
    \ 'i.',
    \ 'I.',
    \ ]

var list_pattern = '\v(' .. join(map(copy(list_symbols), (i, v) => escape(v, '+[].')), '|') .. ')'

export def GetListSymbols(): list<string>
    return copy(list_symbols)
enddef

export def GetListPattern(): string
    return list_pattern
enddef

export def CR_Hacked() # -------------------------------------------------{{{1
  # Needed for hacking <CR> when you are writing a list
  #
  # Check if the current line starts with '- [ ]' or '- '
  # OBS! If there are issues, check 'formatlistpat' value for markdown
  # filetype
  # OBS! The following scan the current line through the less general regex (a
  # regex can be contained in another regex)
  var variant_1 = '-\s\[\(\s*\|x\)*\]\s\+' # - [ ] bla bla bla
  var variant_2 = '-\s\+\(\[\)\@!' # - bla bla bla
  var variant_3 = '\*\s\+' # * bla bla bla
  var variant_4 = '\d\+\.\s\+' # 123. bla bla bla
  var variant_5 = '>\s\+' # Quoted block

  def GetItemSymbol(current_line: string): string
    var item_symbol = ''
    if current_line =~ $'^\s*{variant_1}'
      # If - [x], the next item should be - [ ] anyway.
      item_symbol = $"{current_line->matchstr($'^\s*{variant_1}')
            \ ->substitute('x', ' ', 'g')}"
    elseif current_line =~ $'^\s*{variant_2}'
      item_symbol = $"{current_line->matchstr($'^\s*{variant_2}')}"
    elseif current_line =~ $'^\s*{variant_3}'
      item_symbol = $"{current_line->matchstr($'^\s*{variant_3}')}"
    elseif current_line =~ $'^\s*{variant_5}'
      item_symbol = $"{current_line->matchstr($'^\s*{variant_5}')}"
    elseif current_line =~ $'^\s*{variant_4}'
      # Get rid of the trailing '.' and convert to number
      var curr_nr = str2nr(
        $"{current_line->matchstr($'^\s*{variant_4}')->matchstr('\d\+')}"
      )
      item_symbol = $"{current_line->matchstr($'^\s*{variant_4}')
            \ ->substitute(string(curr_nr), string(curr_nr + 1), '')}"
    endif
    return item_symbol
  enddef

  # Break line at cursor position
  var this_line = strcharpart(getline('.'), 0, col('.') - 1)
  var next_line = strcharpart(getline('.'), col('.') - 1)

  # Handle different cases if the current line is an item of a list
  var line_nr = line('.')
  var current_line = getline(line_nr)
  var item_symbol = GetItemSymbol(current_line)
  if current_line =~ '^\s\{2,}'
    while current_line !~ '^\s*$' && line_nr != 0 && empty(item_symbol)
      line_nr -= 1
      current_line = getline(line_nr)
      item_symbol = GetItemSymbol(current_line)
      echom item_symbol
      if !empty(item_symbol)
        break
      endif
    endwhile
  endif

  # if item_symbol = '' it may still mean that we are not in an item list but
  # yet we have an indendent line, hence, we must preserve the leading spaces
  if empty(item_symbol)
    item_symbol = $"{getline('.')->matchstr($'^\s\+')}"
  endif

  # The following is in case the cursor is on the lhs of the item_symbol
  if col('.') < len(item_symbol)
    if current_line =~ $'^\s*{variant_4}'
      this_line = $"{current_line->matchstr($'^\s*{variant_4}')}"
      next_line = strcharpart(current_line, len(item_symbol))
    else
      this_line = item_symbol
      next_line = strcharpart(current_line, len(item_symbol))
    endif
  endif

  # double <cr> equal to finish the itemization
  if getline('.') == item_symbol || getline('.') =~ '^\s*\d\+\.\s*$'
    this_line = ''
    item_symbol = ''
  endif

  # Add the correct lines
  setline(line('.'), this_line)
  append(line('.'), item_symbol .. next_line)
  cursor(line('.') + 1, len(item_symbol) + 1)
  startinsert

enddef
