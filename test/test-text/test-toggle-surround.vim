vim9script

source ../init.vim
import autoload '../../autoload/mplus/text.vim' as text

setlocal filetype=markdown
setlocal syntax=markdown

# --- ToggleSurround: ADD tests (visual selection path) ---

def Test_toggle_add_bold()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])
    text.ToggleSurround('markdownBold')
    assert_equal('**Hello** world', getline(1))
enddef

def Test_toggle_add_italic()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])
    text.ToggleSurround('markdownItalic')
    assert_equal('*Hello* world', getline(1))
enddef

def Test_toggle_add_strike()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])
    text.ToggleSurround('markdownStrike')
    assert_equal('~~Hello~~ world', getline(1))
enddef

def Test_toggle_add_mark()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])
    text.ToggleSurround('markdownMark')
    assert_equal('==Hello== world', getline(1))
enddef

def Test_toggle_add_code()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])
    text.ToggleSurround('markdownCode')
    assert_equal('`Hello` world', getline(1))
enddef

def Test_toggle_add_bold_multiline()
    setline(1, ['Hello', 'beautiful', 'world'])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 2, 10, 0])
    text.ToggleSurround('markdownBold')
    assert_equal('**Hello', getline(1))
    assert_equal('beautiful**', getline(2))
    assert_equal('world', getline(3))
enddef

def Test_toggle_add_bold_cjk()
    setline(1, '你好世界')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 2, 0])
    text.ToggleSurround('markdownBold')
    assert_equal('**你好**世界', getline(1))
enddef

def Test_toggle_add_italic_cjk()
    setline(1, '你好世界')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 2, 0])
    text.ToggleSurround('markdownItalic')
    assert_equal('*你好*世界', getline(1))
enddef

def Test_toggle_add_bold_emoji()
    setline(1, 'Hello😀世界')
    setcharpos("'[", [0, 1, 6, 0])
    setcharpos("']", [0, 1, 6, 0])
    text.ToggleSurround('markdownBold')
    assert_equal('Hello**😀**世界', getline(1))
enddef

# --- ToggleSurround: REMOVE tests (synID-based cursor detection) ---

def Test_toggle_remove_bold()
    syntax sync fromstart
    setline(1, '**Hello** world')
    setcursorcharpos(1, 5)
    redraw
    text.ToggleSurround('markdownBold')
    assert_equal('Hello world', getline(1))
enddef

def Test_toggle_remove_italic()
    syntax sync fromstart
    setline(1, '*Hello* world')
    setcursorcharpos(1, 3)
    redraw
    text.ToggleSurround('markdownItalic')
    assert_equal('Hello world', getline(1))
enddef

def Test_toggle_remove_strike()
    syntax sync fromstart
    setline(1, '~~Hello~~ world')
    setcursorcharpos(1, 5)
    redraw
    text.ToggleSurround('markdownStrike')
    assert_equal('Hello world', getline(1))
enddef

def Test_toggle_remove_code()
    syntax sync fromstart
    setline(1, '`Hello` world')
    setcursorcharpos(1, 3)
    redraw
    text.ToggleSurround('markdownCode')
    assert_equal('Hello world', getline(1))
enddef

def Test_toggle_remove_bold_cjk()
    syntax sync fromstart
    setline(1, '**你好**世界')
    setcursorcharpos(1, 4)
    redraw
    text.ToggleSurround('markdownBold')
    assert_equal('你好世界', getline(1))
enddef

def Test_toggle_remove_bold_multiline()
    syntax sync fromstart
    setline(1, ['**Hello', 'beautiful**', 'world'])
    setcursorcharpos(1, 5)
    redraw
    text.ToggleSurround('markdownBold')
    assert_equal('Hello', getline(1))
    assert_equal('beautiful', getline(2))
    assert_equal('world', getline(3))
enddef

def Test_toggle_remove_bold_emoji()
    syntax sync fromstart
    setline(1, 'Hello**😀**世界')
    setcursorcharpos(1, 8)
    redraw
    text.ToggleSurround('markdownBold')
    assert_equal('Hello😀世界', getline(1))
enddef

# --- Run all tests ---
Test_toggle_add_bold()
Test_toggle_add_italic()
Test_toggle_add_strike()
Test_toggle_add_mark()
Test_toggle_add_code()
Test_toggle_add_bold_multiline()
Test_toggle_add_bold_cjk()
Test_toggle_add_italic_cjk()
Test_toggle_add_bold_emoji()
Test_toggle_remove_bold()
Test_toggle_remove_italic()
Test_toggle_remove_strike()
Test_toggle_remove_code()
Test_toggle_remove_bold_cjk()
Test_toggle_remove_bold_multiline()
Test_toggle_remove_bold_emoji()

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-toggle-surround: All tests passed'
    quitall!
endif
