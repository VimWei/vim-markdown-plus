vim9script

import autoload './constants.vim' as constants

# ToggleCodeBlock --------------------------------------------------------{{{1
export def ToggleCodeBlock(firstline: number, lastline: number)
  var found_codeblock = false
  for lnum in range(firstline, lastline)
    if synIDattr(synID(lnum, 1, 1), "name") ==# 'markdownCodeBlock'
      found_codeblock = true
      break
    endif
    # 新增：判断是否为包裹行
    var line = getline(lnum)
    if line =~# values(constants.CODEBLOCK_OPEN_DICT)[0] || line =~# values(constants.CODEBLOCK_CLOSE_DICT)[0]
      found_codeblock = true
      break
    endif
  endfor
  if found_codeblock
    # echomsg $'ToggleCodeBlock: UnsetBlock({firstline}, {lastline})'
    UnsetBlock(firstline, lastline)
  else
    # echomsg $'ToggleCodeBlock: SetBlock({firstline}, {lastline})'
    SetBlock(firstline, lastline)
  endif
enddef

# SetBlock ---------------------------------------------------------------{{{1
export def SetBlock(firstline: number, lastline: number)
  const open_block = constants.CODEBLOCK_OPEN_DICT
  const close_block = constants.CODEBLOCK_CLOSE_DICT

  var label = input('Enter code-block language: ')

  var lines = []
  add(lines, $'{keys(open_block)[0]}{label}')
  for lnum in range(firstline, lastline)
    # add(lines, '  ' .. getline(lnum)->substitute('^\\s*', '', ''))
    add(lines, getline(lnum))
  endfor
  add(lines, keys(close_block)[0])

  deletebufline('%', firstline, lastline)
  append(firstline - 1, lines)
enddef

# UnsetBlock -------------------------------------------------------------{{{1
export def UnsetBlock(firstline: number, lastline: number)
  # 收集所有选区内涉及的 codeblock 区间（含包裹行）
  var codeblock_ranges = {}
  var open_pat = values(constants.CODEBLOCK_OPEN_DICT)[0]
  var close_pat = values(constants.CODEBLOCK_CLOSE_DICT)[0]
  for lnum in range(firstline, lastline)
    # 判断是否为 codeblock 内容行或包裹行
    var synname = synIDattr(synID(lnum, 1, 1), "name")
    var line = getline(lnum)
    var is_codeblock_content = synname ==# 'markdownCodeBlock'
    var is_codeblock_wrapper = line =~# open_pat || line =~# close_pat
    if is_codeblock_content || is_codeblock_wrapper
      # 找到该行所在 codeblock 的完整区间 lA, lB
      cursor(lnum, 1)
      const pos_start = searchpos(open_pat, 'bcnW')
      const pos_end = searchpos(close_pat, 'cnW')
      const lA = pos_start[0]
      const lB = pos_end[0]
      if lA > 0 && lB > 0 && lA < lB
        codeblock_ranges[lA] = lB
      endif
    endif
  endfor
  # for 循环之后，补充处理 firstline 是包裹结束行的情况
  if firstline > 1
    var firstline_text = getline(firstline)
    if firstline_text =~# close_pat
      cursor(firstline - 1, 1)
      const pos_start = searchpos(open_pat, 'bcnW')
      const lA = pos_start[0]
      const lB = firstline
      if lA > 0 && lB > 0 && lA < lB
        codeblock_ranges[lA] = lB
      endif
    endif
  endif
  # for 循环之后，补充处理 lastline 是包裹起始行的情况
  if lastline < line('$')
    var lastline_text = getline(lastline)
    var next_synname = synIDattr(synID(lastline + 1, 1, 1), "name")
    if lastline_text =~# open_pat && next_synname ==# 'markdownCodeBlock'
      cursor(lastline + 1, 1)
      const pos_start = searchpos(open_pat, 'bcnW')
      const pos_end = searchpos(close_pat, 'cnW')
      const lA = pos_start[0]
      const lB = pos_end[0]
      if lA > 0 && lB > 0 && lA < lB
        codeblock_ranges[lA] = lB
      endif
    endif
  endif
  # 按 lA 从大到小排序，避免行号变化影响后续删除
  var sorted_lAs = map(sort(keys(codeblock_ranges), 'N'), 'str2nr(v:val)')
  sorted_lAs = reverse(sorted_lAs)
  for lA in sorted_lAs
    var lB = codeblock_ranges[lA]
    # 先去缩进
    # if lA < lB - 1
    #   for lnum_content in range(lA + 1, lB - 1)
    #     var new_line = getline(lnum_content)->substitute('^[ \t]*', '', '')
    #     setline(lnum_content, new_line)
    #   endfor
    # endif
    # 再删除包裹符号（从后往前）
    deletebufline('%', lB)
    deletebufline('%', lA)
  endfor
enddef
