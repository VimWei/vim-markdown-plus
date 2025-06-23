function! mplus#link#ToggleLinkAtCursor() range abort
  " 首先检查光标位置是否在现有链接范围内
  let link_removed = s:remove_link_at_cursor()
  if !link_removed
    " 如果不在链接范围内，创建新链接
    if mode() ==# 'v' || mode() ==# 'V' || mode() ==# '\<C-v>'
      " Visual 模式：处理选中范围
      normal! `<v`>y
      let text = getreg('"')
      let lnum1 = line("'<")
      let col1 = col("'<")
      let lnum2 = line("'>")
      let col2 = col("'>")
      let lines = getline(lnum1, lnum2)
      let first = lines[0]
      let last = lines[-1]
      let before = strpart(first, 0, col1 - 1)
      let after = strpart(last, col2)
      let new_text = '[' . text . ']()'
      let new_lines = split(before . new_text . after, "\n")
      call setline(lnum1, new_lines)
      call cursor(lnum1, col1 + 1)
    else
      " Normal 模式：处理光标下的单词
      normal! viw
      let word = getreg('"')
      let newtext = '[' . word . ']()'
      call setreg('"', newtext)
      normal! viwP
      normal! F)a
    endif
  endif
endfunction

function! mplus#link#ToggleImageLinkAtCursor() range abort
  " 首先检查光标位置是否在现有图片链接范围内
  let link_removed = s:remove_image_link_at_cursor()
  if !link_removed
    " 如果不在图片链接范围内，创建新图片链接
    if mode() ==# 'v' || mode() ==# 'V' || mode() ==# '\<C-v>'
      " Visual 模式：处理选中范围
      normal! `<v`>y
      let text = getreg('"')
      let lnum1 = line("'<")
      let col1 = col("'<")
      let lnum2 = line("'>")
      let col2 = col("'>")
      let lines = getline(lnum1, lnum2)
      let first = lines[0]
      let last = lines[-1]
      let before = strpart(first, 0, col1 - 1)
      let after = strpart(last, col2)
      let new_text = '![' . text . ']()'
      let new_lines = split(before . new_text . after, "\n")
      call setline(lnum1, new_lines)
      call cursor(lnum1, col1 + 2)
    else
      " Normal 模式：处理光标下的单词
      normal! viw
      let word = getreg('"')
      let newtext = '![' . word . ']()'
      call setreg('"', newtext)
      normal! viwP
      normal! F)a
    endif
  endif
endfunction

" 检查并移除光标位置的普通链接
function! s:remove_link_at_cursor() abort
  let lnum = line('.')
  let col = col('.')
  let line_text = getline(lnum)
  let pattern = '\[.\{-}\]\([^)]*\)'
  let start = 0
  
  while 1
    let match_pos = matchstrpos(line_text, pattern, start)
    if empty(match_pos[0])
      break
    endif
    let [matched, mstart, mend] = [match_pos[0], match_pos[1], match_pos[2]]
    " 检查光标是否在这个链接范围内（包括所有位置）
    if col-1 >= mstart && col-1 < mend
      " 提取链接文本
      let link_text = matchstr(matched, '\[\(.\{-}\)\]')
      let link_text = link_text[1:-2]  " 移除 [ 和 ]
      " 移除整个链接
      let new_line = strpart(line_text, 0, mstart) . link_text . strpart(line_text, mend)
      call setline(lnum, new_line)
      call cursor(lnum, mstart + 1)
      return 1
    endif
    if mend <= start
      break
    endif
    let start = mend
  endwhile
  return 0
endfunction

" 检查并移除光标位置的图片链接
function! s:remove_image_link_at_cursor() abort
  let lnum = line('.')
  let col = col('.')
  let line_text = getline(lnum)
  let pattern = '!\[.\{-}\]\([^)]*\)'
  let start = 0
  
  while 1
    let match_pos = matchstrpos(line_text, pattern, start)
    if empty(match_pos[0])
      break
    endif
    let [matched, mstart, mend] = [match_pos[0], match_pos[1], match_pos[2]]
    " 检查光标是否在这个图片链接范围内（包括所有位置）
    if col-1 >= mstart && col-1 < mend
      " 提取图片链接文本
      let link_text = matchstr(matched, '!\[\(.\{-}\)\]')
      let link_text = link_text[2:-2]  " 移除 ![ 和 ]
      " 移除整个图片链接
      let new_line = strpart(line_text, 0, mstart) . link_text . strpart(line_text, mend)
      call setline(lnum, new_line)
      call cursor(lnum, mstart + 1)
      return 1
    endif
    if mend <= start
      break
    endif
    let start = mend
  endwhile
  return 0
endfunction

function! mplus#link#RemoveLinkButKeepUrl() abort
  let lnum = line('.')
  let col = col('.')
  let line_text = getline(lnum)
  
  " 先检查普通链接
  let pattern = '\[.\{-}\]\([^)]*\)'
  let start = 0
  while 1
    let match_pos = matchstrpos(line_text, pattern, start)
    if empty(match_pos[0])
      break
    endif
    let [matched, mstart, mend] = [match_pos[0], match_pos[1], match_pos[2]]
    if col-1 >= mstart && col-1 < mend
      " 提取URL
      let url = matchstr(matched, '\]\([^)]*\)')
      let url = url[2:-2]  " 移除 ]( 和 )
      " 用URL替换整个链接
      let new_line = strpart(line_text, 0, mstart) . url . strpart(line_text, mend)
      call setline(lnum, new_line)
      call cursor(lnum, mstart + 1)
      return
    endif
    if mend <= start
      break
    endif
    let start = mend
  endwhile
  
  " 再检查图片链接
  let pattern = '!\[.\{-}\]\([^)]*\)'
  let start = 0
  while 1
    let match_pos = matchstrpos(line_text, pattern, start)
    if empty(match_pos[0])
      break
    endif
    let [matched, mstart, mend] = [match_pos[0], match_pos[1], match_pos[2]]
    if col-1 >= mstart && col-1 < mend
      " 提取URL
      let url = matchstr(matched, '\]\([^)]*\)')
      let url = url[2:-2]  " 移除 ]( 和 )
      " 用URL替换整个图片链接
      let new_line = strpart(line_text, 0, mstart) . url . strpart(line_text, mend)
      call setline(lnum, new_line)
      call cursor(lnum, mstart + 1)
      return
    endif
    if mend <= start
      break
    endif
    let start = mend
  endwhile
endfunction 