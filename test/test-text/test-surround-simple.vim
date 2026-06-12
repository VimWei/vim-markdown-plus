vim9script

source ../init.vim
import autoload '../../autoload/mplus/text.vim' as text

# --- Test: Bold surround single line ---
def Test_bold_single_line()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 4, 0])
    text.SurroundSimple('markdownBold')
    assert_equal('**Hell**o world', getline(1))
enddef

# --- Test: Italic surround single line ---
def Test_italic_single_line()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 4, 0])
    text.SurroundSimple('markdownItalic')
    assert_equal('*Hell*o world', getline(1))
enddef

# --- Test: Strike surround single line ---
def Test_strike_single_line()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 4, 0])
    text.SurroundSimple('markdownStrike')
    assert_equal('~~Hell~~o world', getline(1))
enddef

# --- Test: Mark surround single line ---
def Test_mark_single_line()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 4, 0])
    text.SurroundSimple('markdownMark')
    assert_equal('==Hell==o world', getline(1))
enddef

# --- Test: Code surround single line ---
def Test_code_single_line()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 4, 0])
    text.SurroundSimple('markdownCode')
    assert_equal('`Hell`o world', getline(1))
enddef

# --- Test: Bold multi-line ---
def Test_bold_multi_line()
    setline(1, ['Hello', 'beautiful', 'world'])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 2, 10, 0])
    text.SurroundSimple('markdownBold')
    assert_equal('**Hello', getline(1))
    assert_equal('beautiful**', getline(2))
    assert_equal('world', getline(3))
enddef

# --- Test: Italic multi-line ---
def Test_italic_multi_line()
    setline(1, ['Hello', 'beautiful', 'world'])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 2, 10, 0])
    text.SurroundSimple('markdownItalic')
    assert_equal('*Hello', getline(1))
    assert_equal('beautiful*', getline(2))
    assert_equal('world', getline(3))
enddef

# --- Test: CJK bold ---
def Test_bold_cjk()
    setline(1, '你好世界')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 2, 0])
    text.SurroundSimple('markdownBold')
    assert_equal('**你好**世界', getline(1))
enddef

# --- Test: CJK italic ---
def Test_italic_cjk()
    setline(1, '你好世界')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 2, 0])
    text.SurroundSimple('markdownItalic')
    assert_equal('*你好*世界', getline(1))
enddef

# --- Test: CJK multi-line ---
def Test_cjk_multi_line()
    setline(1, ['你好', '世界'])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 2, 3, 0])
    text.SurroundSimple('markdownBold')
    assert_equal('**你好', getline(1))
    assert_equal('世界**', getline(2))
enddef

# --- Test: ASCII + CJK mixed ---
def Test_ascii_cjk_mixed()
    setline(1, 'Hello世界')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 6, 0])
    text.SurroundSimple('markdownBold')
    assert_equal('**Hello世**界', getline(1))
enddef

# --- Test: CJK + ASCII leading ---
def Test_cjk_ascii_leading()
    setline(1, '世界Hello')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 3, 0])
    text.SurroundSimple('markdownBold')
    assert_equal('**世界H**ello', getline(1))
enddef

# --- Test: Emoji single ---
def Test_bold_emoji()
    setline(1, 'Hello😀世界')
    setcharpos("'[", [0, 1, 6, 0])
    setcharpos("']", [0, 1, 6, 0])
    text.SurroundSimple('markdownBold')
    assert_equal('Hello**😀**世界', getline(1))
enddef

# --- Test: Single character selection ---
def Test_single_char()
    setline(1, 'Hello')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 1, 0])
    text.SurroundSimple('markdownBold')
    assert_equal('**H**ello', getline(1))
enddef

# --- Run all tests ---
g:RunTestInBuffer(function('Test_bold_single_line'))
g:RunTestInBuffer(function('Test_italic_single_line'))
g:RunTestInBuffer(function('Test_strike_single_line'))
g:RunTestInBuffer(function('Test_mark_single_line'))
g:RunTestInBuffer(function('Test_code_single_line'))
g:RunTestInBuffer(function('Test_bold_multi_line'))
g:RunTestInBuffer(function('Test_italic_multi_line'))
g:RunTestInBuffer(function('Test_bold_cjk'))
g:RunTestInBuffer(function('Test_italic_cjk'))
g:RunTestInBuffer(function('Test_cjk_multi_line'))
g:RunTestInBuffer(function('Test_ascii_cjk_mixed'))
g:RunTestInBuffer(function('Test_cjk_ascii_leading'))
g:RunTestInBuffer(function('Test_bold_emoji'))
g:RunTestInBuffer(function('Test_single_char'))

# --- Report ---
if len(v:errors) > 0
    for err in v:errors
        echomsg err
    endfor
    cquit!
else
    echo 'test-surround-simple: All tests passed'
    quitall!
endif
