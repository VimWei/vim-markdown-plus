vim9script

source ../init.vim
import autoload '../../autoload/mplus/list.vim' as lst

# --- Test: Change symbol from hyphen to star ---
def Test_change_symbol_hyphen_to_star()
    setline(1, '- Item one')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('*', 1)
    assert_equal('* Item one', getline(1))
enddef

# --- Test: Change symbol from star to plus ---
def Test_change_symbol_star_to_plus()
    setline(1, '* Item one')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('+', 1)
    assert_equal('+ Item one', getline(1))
enddef

# --- Test: Change symbol to numeric list ---
def Test_change_symbol_to_number()
    setline(1, '- Item one')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('1.', 1)
    assert_equal('1. Item one', getline(1))
enddef

# --- Test: Change symbol to alphabetic list ---
def Test_change_symbol_to_alpha()
    setline(1, '- Item one')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('a.', 1)
    assert_equal('a. Item one', getline(1))
enddef

# --- Test: Delete list symbol ---
def Test_change_symbol_delete()
    setline(1, '- Item one')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('d', 1)
    assert_equal('Item one', getline(1))
enddef

# --- Test: Add symbol to non-list line ---
def Test_change_symbol_non_list()
    setline(1, 'Plain text')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('-', 1)
    assert_equal('- Plain text', getline(1))
enddef

# --- Test: Change symbol on indented list item ---
def Test_change_symbol_indented()
    setline(1, '  - Item one')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('*', 1)
    assert_equal('  * Item one', getline(1))
enddef

# --- Test: Change symbol on multiple lines ---
def Test_change_symbol_multiple_lines()
    setline(1, ['- Item one', '- Item two', '- Item three'])
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('*', 3)
    assert_equal('* Item one', getline(1))
    assert_equal('* Item two', getline(2))
    assert_equal('* Item three', getline(3))
enddef

# --- Test: Change symbol with CJK text ---
def Test_change_symbol_cjk()
    setline(1, '- 中文项目')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('*', 1)
    assert_equal('* 中文项目', getline(1))
enddef

# --- Test: GetListSymbols returns expected list ---
def Test_get_list_symbols()
    var symbols = lst.GetListSymbols()
    assert_equal('*', symbols[0])
    assert_equal('-', symbols[1])
    assert_equal('+', symbols[2])
    assert_equal('1.', symbols[3])
    assert_equal('a.', symbols[4])
    assert_equal('A.', symbols[5])
    assert_equal('i.', symbols[6])
    assert_equal('I.', symbols[7])
    assert_equal(8, len(symbols))
enddef

# --- Test: GetListPattern returns valid pattern ---
def Test_get_list_pattern()
    var pattern = lst.GetListPattern()
    assert_true(len(pattern) > 0)
    assert_true('-' =~# pattern)
    assert_true('*' =~# pattern)
    assert_true('+' =~# pattern)
    assert_true('1.' =~# pattern)
    assert_true('a.' =~# pattern)
enddef

# --- Test: Delete symbol from indented list item ---
def Test_change_symbol_delete_indented()
    setline(1, '  - Item one')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('d', 1)
    assert_equal('  Item one', getline(1))
enddef

# --- Test: Change symbol preserves content after symbol ---
def Test_change_symbol_preserves_content()
    setline(1, '- Item with **bold** and *italic*')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('+', 1)
    assert_equal('+ Item with **bold** and *italic*', getline(1))
enddef

# --- Test: Change symbol on numeric list to star ---
def Test_change_symbol_numeric_to_star()
    setline(1, '1. First item')
    setcursorcharpos(1, 1)
    lst.ChangeSymbol('*', 1)
    assert_equal('* First item', getline(1))
enddef

# --- Run all tests ---
g:RunTestInBuffer(function('Test_change_symbol_hyphen_to_star'))
g:RunTestInBuffer(function('Test_change_symbol_star_to_plus'))
g:RunTestInBuffer(function('Test_change_symbol_to_number'))
g:RunTestInBuffer(function('Test_change_symbol_to_alpha'))
g:RunTestInBuffer(function('Test_change_symbol_delete'))
g:RunTestInBuffer(function('Test_change_symbol_non_list'))
g:RunTestInBuffer(function('Test_change_symbol_indented'))
g:RunTestInBuffer(function('Test_change_symbol_multiple_lines'))
g:RunTestInBuffer(function('Test_change_symbol_cjk'))
g:RunTestInBuffer(function('Test_get_list_symbols'))
g:RunTestInBuffer(function('Test_get_list_pattern'))
g:RunTestInBuffer(function('Test_change_symbol_delete_indented'))
g:RunTestInBuffer(function('Test_change_symbol_preserves_content'))
g:RunTestInBuffer(function('Test_change_symbol_numeric_to_star'))

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-change-symbol: All tests passed'
    quitall!
endif
