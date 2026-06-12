vim9script

source ../init.vim
import autoload '../../autoload/mplus/utils.vim' as utils

# --- Test: IsLess basic comparison (simple test first) ---
def Test_is_less_basic()
    assert_true(utils.IsLess([1, 2], [1, 3]))
    assert_false(utils.IsLess([1, 3], [1, 2]))
enddef

# --- Test: IsGreater basic comparison ---
def Test_is_greater_basic()
    assert_true(utils.IsGreater([1, 3], [1, 2]))
    assert_false(utils.IsGreater([1, 2], [1, 3]))
enddef

# --- Test: IsEqual basic comparison ---
def Test_is_equal_basic()
    assert_true(utils.IsEqual([1, 2], [1, 2]))
    assert_false(utils.IsEqual([1, 2], [1, 3]))
enddef

# --- Run simple tests ---
Test_is_less_basic()
Test_is_greater_basic()
Test_is_equal_basic()

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
