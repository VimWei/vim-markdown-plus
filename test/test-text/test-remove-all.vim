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

# --- RemoveAll: emoji tests ---

def Test_remove_all_emoji_bold()
    syntax sync fromstart
    setline(1, 'Hello**😀**世界')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 12, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello😀世界', getline(1))
enddef

# --- RemoveAll: multi-paragraph tests ---

def Test_remove_all_two_paragraphs()
    syntax sync fromstart
    setline(1, ['**Hello** world', '', '*foo* bar'])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 3, 8, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('Hello world', getline(1))
    assert_equal('', getline(2))
    assert_equal('foo bar', getline(3))
enddef

def Test_remove_all_six_paragraphs()
    syntax sync fromstart
    setline(1, [
        \ '**para1**',
        \ '',
        \ '*para2*',
        \ '',
        \ '~~para3~~',
        \ '',
        \ '==para4==',
        \ '',
        \ '`para5`',
        \ '',
        \ '**para6**'
        \ ])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 11, 10, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('para1', getline(1))
    assert_equal('', getline(2))
    assert_equal('para2', getline(3))
    assert_equal('', getline(4))
    assert_equal('para3', getline(5))
    assert_equal('', getline(6))
    assert_equal('para4', getline(7))
    assert_equal('', getline(8))
    assert_equal('para5', getline(9))
    assert_equal('', getline(10))
    assert_equal('para6', getline(11))
enddef

def Test_remove_all_mixed_styles_paragraphs()
    syntax sync fromstart
    setline(1, [
        \ '**bold** and *italic*',
        \ '',
        \ '~~strike~~ and ==mark=='
        \ ])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 3, 22, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('strike and mark', getline(3))
enddef

def Test_remove_all_cjk_paragraphs()
    syntax sync fromstart
    setline(1, [
        \ '**粗体**和*斜体*',
        \ '',
        \ '~~删除线~~和==标记=='
        \ ])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 3, 10, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('粗体和斜体', getline(1))
    assert_equal('', getline(2))
    assert_equal('删除线和标记', getline(3))
enddef

def Test_remove_all_selection_starts_ends_blank()
    syntax sync fromstart
    setline(1, ['', '**Hello**', '', '**world**', ''])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 5, 1, 0])
    text.RemoveAll('markdownRemoveAll')
    assert_equal('', getline(1))
    assert_equal('Hello', getline(2))
    assert_equal('', getline(3))
    assert_equal('world', getline(4))
    assert_equal('', getline(5))
enddef

# --- RemoveSurrounding: tests (uses synID via IsInRange) ---

# --- RemoveAll: CJK linewise tests (regression: cursor byte-column bug) ---

def Test_remove_all_cjk_bold_linewise()
    syntax sync fromstart
    setline(1, '**在已有 Windows Terminal 窗口的新 tab 中打开**')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, strchars(getline(1)), 0])
    text.RemoveAll('markdownRemoveAll', 'line')
    assert_equal('在已有 Windows Terminal 窗口的新 tab 中打开', getline(1))
enddef

def Test_remove_all_cjk_italic_linewise()
    syntax sync fromstart
    setline(1, '*中文斜体测试*')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, strchars(getline(1)), 0])
    text.RemoveAll('markdownRemoveAll', 'line')
    assert_equal('中文斜体测试', getline(1))
enddef

def Test_remove_all_cjk_strike_linewise()
    syntax sync fromstart
    setline(1, '~~中文删除线测试~~')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, strchars(getline(1)), 0])
    text.RemoveAll('markdownRemoveAll', 'line')
    assert_equal('中文删除线测试', getline(1))
enddef

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
g:RunTestInBuffer(function('Test_remove_all_bold'))
g:RunTestInBuffer(function('Test_remove_all_italic'))
g:RunTestInBuffer(function('Test_remove_all_strike'))
g:RunTestInBuffer(function('Test_remove_all_mark'))
g:RunTestInBuffer(function('Test_remove_all_code'))
g:RunTestInBuffer(function('Test_remove_all_nested_bold_italic'))
g:RunTestInBuffer(function('Test_remove_all_multiple_styles'))
g:RunTestInBuffer(function('Test_remove_all_multiline_bold'))
g:RunTestInBuffer(function('Test_remove_all_multiline_mixed'))
g:RunTestInBuffer(function('Test_remove_all_emoji_bold'))
g:RunTestInBuffer(function('Test_remove_all_cjk_bold_linewise'))
g:RunTestInBuffer(function('Test_remove_all_cjk_italic_linewise'))
g:RunTestInBuffer(function('Test_remove_all_cjk_strike_linewise'))
g:RunTestInBuffer(function('Test_remove_all_two_paragraphs'))
g:RunTestInBuffer(function('Test_remove_all_six_paragraphs'))
g:RunTestInBuffer(function('Test_remove_all_mixed_styles_paragraphs'))
g:RunTestInBuffer(function('Test_remove_all_cjk_paragraphs'))
g:RunTestInBuffer(function('Test_remove_all_selection_starts_ends_blank'))
g:RunTestInBuffer(function('Test_remove_surrounding_bold'))
g:RunTestInBuffer(function('Test_remove_surrounding_italic'))
g:RunTestInBuffer(function('Test_remove_surrounding_strike'))
g:RunTestInBuffer(function('Test_remove_surrounding_cjk_bold'))
g:RunTestInBuffer(function('Test_remove_surrounding_multiline_bold'))

# --- Report ---
if len(v:errors) > 0
    for err in v:errors
        echomsg err
    endfor
    cquit!
else
    echo 'test-remove-all: All tests passed'
    quitall!
endif
