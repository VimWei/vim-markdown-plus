vim9script

source ../init.vim
import autoload '../../autoload/mplus/text.vim' as text

var errors = []

def Test(name: string, ln: string, expected: string, 
         \ c1: number, c2: number, cursor_col: number, style: string, 
         \ visual_type: string = 'char')
    new
    setlocal filetype=markdown
    runtime! syntax/markdown.vim
    syntax sync fromstart
    setline(1, ln)
    redraw
    setcursorcharpos(1, cursor_col)
    redraw
    setcharpos("'[", [0, 1, c1, 0])
    setcharpos("']", [0, 1, c2, 0])
    try
        text.ToggleSurround(style, visual_type)
        var actual = getline(1)
        if actual != expected
            add(errors, printf('%s: expected [%s] got [%s]', name, expected, actual))
        endif
    catch /.*/
        add(errors, printf('%s: exception: %s', name, v:exception))
    finally
        bwipe!
    endtry
enddef

var tline = '在已**有 Windows Terminal 窗口**的新 tab 中打开'

Test('S1:full+cursor@start', tline,
    \ '**在已有 Windows Terminal 窗口的新 tab 中打开**',
    \ 1, 37, 1, 'markdownBold', 'line')

Test('S1:full+cursor@end', tline,
    \ '**在已有 Windows Terminal 窗口的新 tab 中打开**',
    \ 1, 37, 37, 'markdownBold', 'line')

Test('S1:full+cursor in bold', tline,
    \ '**在已有 Windows Terminal 窗口的新 tab 中打开**',
    \ 1, 37, 8, 'markdownBold', 'line')

Test('S2:partial+cursor@start', tline,
    \ '**在已有 Windows Terminal 窗口**的新 tab 中打开',
    \ 1, 5, 1, 'markdownBold', 'char')

Test('S2:partial+cursor@end', tline,
    \ '**在已有 Windows Terminal 窗口**的新 tab 中打开',
    \ 1, 5, 5, 'markdownBold', 'char')

Test('S3:mid extend', tline,
    \ '**在已有 Windows Terminal 窗口**的新 tab 中打开',
    \ 1, 13, 1, 'markdownBold', 'char')

# New case: bold starts at col 1, toggle entire line should re-wrap
var tline2 = '**在已有 Windows Terminal 窗口**的新 tab 中打开'

Test('S4:bold at start, full line toggle', tline2,
    \ '**在已有 Windows Terminal 窗口的新 tab 中打开**',
    \ 1, 37, 1, 'markdownBold', 'line')

Test('S4:bold at start, full line, cursor in bold', tline2,
    \ '**在已有 Windows Terminal 窗口的新 tab 中打开**',
    \ 1, 37, 4, 'markdownBold', 'line')

Test('S4:bold at start, full line, cursor at end', tline2,
    \ '**在已有 Windows Terminal 窗口的新 tab 中打开**',
    \ 1, 37, 37, 'markdownBold', 'line')

if len(errors) > 0
    for e in errors
        echomsg e
    endfor
    cquit!
else
    echomsg 'test-overlap-toggle: All tests passed'
    quitall!
endif
