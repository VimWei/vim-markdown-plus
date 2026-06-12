vim9script

source ../init.vim
import autoload '../../autoload/mplus/todo.vim' as todo

# --- Test: MaturityNext [ ] -> [.] ---
def Test_maturity_next_space_to_dot()
    setline(1, '- [ ] Item text')
    todo.MaturityNext(1, 1)
    assert_equal('- [.] Item text', getline(1))
enddef

# --- Test: MaturityNext [.] -> [o] ---
def Test_maturity_next_dot_to_o()
    setline(1, '- [.] Item text')
    todo.MaturityNext(1, 1)
    assert_equal('- [o] Item text', getline(1))
enddef

# --- Test: MaturityNext [o] -> [O] ---
def Test_maturity_next_o_to_O()
    setline(1, '- [o] Item text')
    todo.MaturityNext(1, 1)
    assert_equal('- [O] Item text', getline(1))
enddef

# --- Test: MaturityNext [O] -> [x] ---
def Test_maturity_next_O_to_x()
    setline(1, '- [O] Item text')
    todo.MaturityNext(1, 1)
    assert_equal('- [x] Item text', getline(1))
enddef

# --- Test: MaturityNext [x] stays [x] (final state) ---
def Test_maturity_next_x_stays()
    setline(1, '- [x] Item text')
    todo.MaturityNext(1, 1)
    assert_equal('- [x] Item text', getline(1))
enddef

# --- Test: MaturityNext non-checkbox converts to todo ---
def Test_maturity_next_non_checkbox()
    setline(1, '- Item text')
    todo.MaturityNext(1, 1)
    assert_equal('- [ ] Item text', getline(1))
enddef

# --- Test: MaturityPrevious [x] -> [O] ---
def Test_maturity_previous_x_to_O()
    setline(1, '- [x] Item text')
    todo.MaturityPrevious(1, 1)
    assert_equal('- [O] Item text', getline(1))
enddef

# --- Test: MaturityPrevious [O] -> [o] ---
def Test_maturity_previous_O_to_o()
    setline(1, '- [O] Item text')
    todo.MaturityPrevious(1, 1)
    assert_equal('- [o] Item text', getline(1))
enddef

# --- Test: MaturityPrevious [o] -> [.] ---
def Test_maturity_previous_o_to_dot()
    setline(1, '- [o] Item text')
    todo.MaturityPrevious(1, 1)
    assert_equal('- [.] Item text', getline(1))
enddef

# --- Test: MaturityPrevious [.] -> [ ] ---
def Test_maturity_previous_dot_to_space()
    setline(1, '- [.] Item text')
    todo.MaturityPrevious(1, 1)
    assert_equal('- [ ] Item text', getline(1))
enddef

# --- Test: MaturityPrevious [ ] stays [ ] (initial state) ---
def Test_maturity_previous_space_stays()
    setline(1, '- [ ] Item text')
    todo.MaturityPrevious(1, 1)
    assert_equal('- [ ] Item text', getline(1))
enddef

# --- Test: MaturityPrevious non-checkbox converts to todo ---
def Test_maturity_previous_non_checkbox()
    setline(1, '- Item text')
    todo.MaturityPrevious(1, 1)
    assert_equal('- [ ] Item text', getline(1))
enddef

# --- Test: CJK text ---
def Test_maturity_cjk()
    setline(1, '- [ ] 中文内容')
    todo.MaturityNext(1, 1)
    assert_equal('- [.] 中文内容', getline(1))
enddef

# --- Run all tests ---
g:RunTestInBuffer(function('Test_maturity_next_space_to_dot'))
g:RunTestInBuffer(function('Test_maturity_next_dot_to_o'))
g:RunTestInBuffer(function('Test_maturity_next_o_to_O'))
g:RunTestInBuffer(function('Test_maturity_next_O_to_x'))
g:RunTestInBuffer(function('Test_maturity_next_x_stays'))
g:RunTestInBuffer(function('Test_maturity_next_non_checkbox'))
g:RunTestInBuffer(function('Test_maturity_previous_x_to_O'))
g:RunTestInBuffer(function('Test_maturity_previous_O_to_o'))
g:RunTestInBuffer(function('Test_maturity_previous_o_to_dot'))
g:RunTestInBuffer(function('Test_maturity_previous_dot_to_space'))
g:RunTestInBuffer(function('Test_maturity_previous_space_stays'))
g:RunTestInBuffer(function('Test_maturity_previous_non_checkbox'))
g:RunTestInBuffer(function('Test_maturity_cjk'))

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-maturity: All tests passed'
    quitall!
endif
