vim9script

source ../init.vim
import autoload '../../autoload/mplus/todo.vim' as todo

# --- Test: Toggle [ ] to [x] ---
def Test_done_toggle_unchecked_to_checked()
    setline(1, '- [ ] Item text')
    todo.DoneToggle(1, 1)
    assert_equal('- [x] Item text', getline(1))
enddef

# --- Test: Toggle [x] to [ ] ---
def Test_done_toggle_checked_to_unchecked()
    setline(1, '- [x] Item text')
    todo.DoneToggle(1, 1)
    assert_equal('- [ ] Item text', getline(1))
enddef

# --- Test: Toggle [X] to [ ] ---
def Test_done_toggle_upper_X_to_unchecked()
    setline(1, '- [X] Item text')
    todo.DoneToggle(1, 1)
    assert_equal('- [ ] Item text', getline(1))
enddef

# --- Test: Toggle [.] to [x] ---
def Test_done_toggle_dot_to_checked()
    setline(1, '- [.] Item text')
    todo.DoneToggle(1, 1)
    assert_equal('- [x] Item text', getline(1))
enddef

# --- Test: Toggle [-] to [x] ---
def Test_done_toggle_dash_to_checked()
    setline(1, '- [-] Item text')
    todo.DoneToggle(1, 1)
    assert_equal('- [x] Item text', getline(1))
enddef

# --- Test: Non-checkbox line converts to todo ---
def Test_done_toggle_non_checkbox()
    setline(1, '- Item text')
    todo.DoneToggle(1, 1)
    assert_equal('- [ ] Item text', getline(1))
enddef

# --- Test: Multiple lines ---
def Test_done_toggle_multiple_lines()
    setline(1, ['- [ ] Item one', '- [x] Item two'])
    todo.DoneToggle(1, 2)
    assert_equal('- [x] Item one', getline(1))
    assert_equal('- [ ] Item two', getline(2))
enddef

# --- Test: CJK text ---
def Test_done_toggle_cjk()
    setline(1, '- [ ] 中文内容')
    todo.DoneToggle(1, 1)
    assert_equal('- [x] 中文内容', getline(1))
enddef

# --- Run all tests ---
Test_done_toggle_unchecked_to_checked()
Test_done_toggle_checked_to_unchecked()
Test_done_toggle_upper_X_to_unchecked()
Test_done_toggle_dot_to_checked()
Test_done_toggle_dash_to_checked()
Test_done_toggle_non_checkbox()
Test_done_toggle_multiple_lines()
Test_done_toggle_cjk()

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-done-toggle: All tests passed'
    quitall!
endif
