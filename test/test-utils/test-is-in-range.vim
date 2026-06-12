vim9script

source ../init.vim
import autoload '../../autoload/mplus/utils.vim' as utils

# --- Comparison function tests ---

def Test_is_less_basic()
    assert_true(utils.IsLess([1, 2], [1, 3]))
    assert_false(utils.IsLess([1, 3], [1, 2]))
enddef

def Test_is_greater_basic()
    assert_true(utils.IsGreater([1, 3], [1, 2]))
    assert_false(utils.IsGreater([1, 2], [1, 3]))
enddef

def Test_is_equal_basic()
    assert_true(utils.IsEqual([1, 2], [1, 2]))
    assert_false(utils.IsEqual([1, 2], [1, 3]))
enddef

# --- IsInRange tests (synID-based) ---
# Each test uses :syntax sync fromstart to ensure clean syntax state

def Test_is_in_range_bold()
    syntax sync fromstart
    setline(1, '**bold text** normal')
    setcursorcharpos(1, 5)
    redraw
    var r = utils.IsInRange()
    assert_true(has_key(r, 'markdownBold'))
    assert_equal([[1, 3], [1, 11]], r['markdownBold'])
enddef

def Test_is_in_range_italic()
    syntax sync fromstart
    setline(1, '*italic text* normal')
    setcursorcharpos(1, 5)
    redraw
    var r = utils.IsInRange()
    assert_true(has_key(r, 'markdownItalic'))
    assert_equal([[1, 2], [1, 12]], r['markdownItalic'])
enddef

def Test_is_in_range_strike()
    syntax sync fromstart
    setline(1, '~~strike text~~ normal')
    setcursorcharpos(1, 5)
    redraw
    var r = utils.IsInRange()
    assert_true(has_key(r, 'markdownStrike'))
    assert_equal([[1, 3], [1, 13]], r['markdownStrike'])
enddef

def Test_is_in_range_code()
    syntax sync fromstart
    setline(1, '`code text` normal')
    setcursorcharpos(1, 5)
    redraw
    var r = utils.IsInRange()
    assert_true(has_key(r, 'markdownCode'))
    assert_equal([[1, 2], [1, 10]], r['markdownCode'])
enddef

def Test_is_in_range_underscore_bold()
    syntax sync fromstart
    setline(1, '__bold text__ normal')
    setcursorcharpos(1, 5)
    redraw
    var r = utils.IsInRange()
    assert_true(has_key(r, 'markdownBoldU'))
    assert_equal([[1, 3], [1, 11]], r['markdownBoldU'])
enddef

def Test_is_in_range_outside()
    syntax sync fromstart
    setline(1, '**bold text** normal')
    setcursorcharpos(1, 16)
    redraw
    var r = utils.IsInRange()
    assert_true(empty(r))
enddef

def Test_is_in_range_cjk_bold()
    syntax sync fromstart
    setline(1, '**你好世界**文本')
    setcursorcharpos(1, 5)
    redraw
    var r = utils.IsInRange()
    assert_true(has_key(r, 'markdownBold'))
    assert_equal([[1, 3], [1, 6]], r['markdownBold'])
enddef

def Test_is_in_range_multiline_bold_line1()
    syntax sync fromstart
    setline(1, ['**Hello', 'world**', 'after'])
    setcursorcharpos(1, 5)
    redraw
    var r = utils.IsInRange()
    assert_true(has_key(r, 'markdownBold'))
    assert_equal([[1, 3], [2, 5]], r['markdownBold'])
enddef

def Test_is_in_range_multiline_bold_line2()
    syntax sync fromstart
    setline(1, ['**Hello', 'world**', 'after'])
    setcursorcharpos(2, 3)
    redraw
    var r = utils.IsInRange()
    assert_true(has_key(r, 'markdownBold'))
    assert_equal([[1, 3], [2, 5]], r['markdownBold'])
enddef

def Test_is_in_range_emoji_bold()
    syntax sync fromstart
    setline(1, '**Hello😀** after')
    setcursorcharpos(1, 5)
    redraw
    var r = utils.IsInRange()
    assert_true(has_key(r, 'markdownBold'))
    assert_equal([[1, 3], [1, 8]], r['markdownBold'])
enddef

def Test_is_in_range_ascii_cjk_mixed()
    syntax sync fromstart
    setline(1, 'Hello**你好world** end')
    setcursorcharpos(1, 10)
    redraw
    var r = utils.IsInRange()
    assert_true(has_key(r, 'markdownBold'))
    assert_equal([[1, 8], [1, 14]], r['markdownBold'])
enddef

# --- Run all tests ---
Test_is_less_basic()
Test_is_greater_basic()
Test_is_equal_basic()
Test_is_in_range_bold()
Test_is_in_range_italic()
Test_is_in_range_strike()
Test_is_in_range_code()
Test_is_in_range_underscore_bold()
Test_is_in_range_outside()
Test_is_in_range_cjk_bold()
Test_is_in_range_multiline_bold_line1()
Test_is_in_range_multiline_bold_line2()
Test_is_in_range_emoji_bold()
Test_is_in_range_ascii_cjk_mixed()

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-is-in-range: All tests passed'
    quitall!
endif
