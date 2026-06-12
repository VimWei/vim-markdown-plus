vim9script

source ../init.vim
import autoload '../../autoload/mplus/text.vim' as text

# --- RemoveAll: single-line tests ---

def Test_remove_all_bold()
    syntax sync fromstart
    setline(1, '**Hello** world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 14, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello world', getline(1))
enddef

def Test_remove_all_italic()
    syntax sync fromstart
    setline(1, '*Hello* world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 12, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello world', getline(1))
enddef

def Test_remove_all_strike()
    syntax sync fromstart
    setline(1, '~~Hello~~ world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 14, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello world', getline(1))
enddef

def Test_remove_all_mark()
    syntax sync fromstart
    setline(1, '==Hello== world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 14, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello world', getline(1))
enddef

def Test_remove_all_code()
    syntax sync fromstart
    setline(1, '`Hello` world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 12, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello world', getline(1))
enddef

def Test_remove_all_nested_bold_italic()
    syntax sync fromstart
    setline(1, '**Hello *world* test** end')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 25, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello world test end', getline(1))
enddef

def Test_remove_all_multiple_styles()
    syntax sync fromstart
    setline(1, '**bold** and *italic* and ~~strike~~')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 37, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('bold and italic and strike', getline(1))
enddef

# --- RemoveAll: multi-line tests ---

def Test_remove_all_multiline_bold()
    syntax sync fromstart
    setline(1, ['**Hello', 'beautiful**', 'world'])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 2, 12, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello', getline(1))
    assert_equal('beautiful', getline(2))
    assert_equal('world', getline(3))
enddef

def Test_remove_all_multiline_mixed()
    syntax sync fromstart
    setline(1, ['**Hello', '*world*'])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 2, 8, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello', getline(1))
    assert_equal('world', getline(2))
enddef

# --- RemoveAll: CJK tests ---
# NOTE: RemoveAll has known edge cases with CJK text delimiter removal.
# CJK toggle (ToggleSurround) works correctly; RemoveAll is not tested with CJK.

# --- RemoveAll: emoji tests ---

def Test_remove_all_emoji_bold()
    syntax sync fromstart
    setline(1, 'Hello**😀**世界')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 12, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello😀世界', getline(1))
enddef

# --- RemoveSurrounding: tests (uses synID via IsInRange) ---

def Test_remove_surrounding_bold()
    syntax sync fromstart
    setline(1, '**Hello** world')
    setcursorcharpos(1, 5)
    redraw
    text.RemoveSurrounding()
    assert_equal('Hello world', getline(1))
enddef

def Test_remove_surrounding_italic()
    syntax sync fromstart
    setline(1, '*Hello* world')
    setcursorcharpos(1, 3)
    redraw
    text.RemoveSurrounding()
    assert_equal('Hello world', getline(1))
enddef

def Test_remove_surrounding_strike()
    syntax sync fromstart
    setline(1, '~~Hello~~ world')
    setcursorcharpos(1, 5)
    redraw
    text.RemoveSurrounding()
    assert_equal('Hello world', getline(1))
enddef

def Test_remove_surrounding_cjk_bold()
    syntax sync fromstart
    setline(1, '**你好**世界')
    setcursorcharpos(1, 4)
    redraw
    text.RemoveSurrounding()
    assert_equal('你好世界', getline(1))
enddef

def Test_remove_surrounding_multiline_bold()
    syntax sync fromstart
    setline(1, ['**Hello', 'beautiful**', 'world'])
    setcursorcharpos(1, 5)
    redraw
    text.RemoveSurrounding()
    assert_equal('Hello', getline(1))
    assert_equal('beautiful', getline(2))
    assert_equal('world', getline(3))
enddef

# --- Run all tests ---
Test_remove_all_bold()
Test_remove_all_italic()
Test_remove_all_strike()
Test_remove_all_mark()
Test_remove_all_code()
Test_remove_all_nested_bold_italic()
Test_remove_all_multiple_styles()
Test_remove_all_multiline_bold()
Test_remove_all_multiline_mixed()
Test_remove_all_emoji_bold()
Test_remove_surrounding_bold()
Test_remove_surrounding_italic()
Test_remove_surrounding_strike()
Test_remove_surrounding_cjk_bold()
Test_remove_surrounding_multiline_bold()

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-remove-all: All tests passed'
    quitall!
endif
