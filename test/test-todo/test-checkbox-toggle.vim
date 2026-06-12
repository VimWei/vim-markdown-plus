vim9script

source ../init.vim
import autoload '../../autoload/mplus/todo.vim' as todo

setlocal filetype=markdown
setlocal syntax=markdown

# --- Test: Convert normal list item to todo ---
def Test_checkbox_toggle_normal_list()
    setline(1, '- Item text')
    todo.CheckboxToggle(1, 1)
    assert_equal('- [ ] Item text', getline(1))
enddef

# --- Test: Convert normal list item with star ---
def Test_checkbox_toggle_star_list()
    setline(1, '* Item text')
    todo.CheckboxToggle(1, 1)
    assert_equal('* [ ] Item text', getline(1))
enddef

# --- Test: Convert normal list item with plus ---
def Test_checkbox_toggle_plus_list()
    setline(1, '+ Item text')
    todo.CheckboxToggle(1, 1)
    assert_equal('+ [ ] Item text', getline(1))
enddef

# --- Test: Remove checkbox from todo item ---
def Test_checkbox_toggle_remove_checkbox()
    setline(1, '- [ ] Item text')
    todo.CheckboxToggle(1, 1)
    assert_equal('- Item text', getline(1))
enddef

# --- Test: Remove checkbox from done item ---
def Test_checkbox_toggle_remove_done()
    setline(1, '- [x] Item text')
    todo.CheckboxToggle(1, 1)
    assert_equal('- Item text', getline(1))
enddef

# --- Test: Convert plain text to todo list ---
def Test_checkbox_toggle_plain_text()
    setline(1, 'Plain text')
    todo.CheckboxToggle(1, 1)
    assert_equal('* [ ] Plain text', getline(1))
enddef

# --- Test: Multiple lines ---
def Test_checkbox_toggle_multiple_lines()
    setline(1, ['- Item one', '- Item two'])
    todo.CheckboxToggle(1, 2)
    assert_equal('- [ ] Item one', getline(1))
    assert_equal('- [ ] Item two', getline(2))
enddef

# --- Test: Indented list item ---
def Test_checkbox_toggle_indented()
    setline(1, '  - Indented item')
    todo.CheckboxToggle(1, 1)
    assert_equal('  - [ ] Indented item', getline(1))
enddef

# --- Test: CJK text ---
def Test_checkbox_toggle_cjk()
    setline(1, '- 中文内容')
    todo.CheckboxToggle(1, 1)
    assert_equal('- [ ] 中文内容', getline(1))
enddef

# --- Run all tests ---
Test_checkbox_toggle_normal_list()
Test_checkbox_toggle_star_list()
Test_checkbox_toggle_plus_list()
Test_checkbox_toggle_remove_checkbox()
Test_checkbox_toggle_remove_done()
Test_checkbox_toggle_plain_text()
Test_checkbox_toggle_multiple_lines()
Test_checkbox_toggle_indented()
Test_checkbox_toggle_cjk()

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-checkbox-toggle: All tests passed'
    quitall!
endif
