vim9script

source ../init.vim
import autoload '../../autoload/mplus/utils.vim' as utils

# --- Test: IsLess basic comparison ---
def Test_is_less_basic()
    assert_true(utils.IsLess([1, 2], [1, 3]))
    assert_false(utils.IsLess([1, 3], [1, 2]))
enddef

# --- Test: IsLess different length ---
def Test_is_less_different_length()
    # [1] and [1, 2] have common prefix [1], so IsLess returns false
    assert_false(utils.IsLess([1], [1, 2]))
    assert_false(utils.IsLess([1, 2], [1]))
    # [1] < [2] regardless of length
    assert_true(utils.IsLess([1], [2, 0]))
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

# --- Test: IsEqual different length ---
def Test_is_equal_different_length()
    assert_true(utils.IsEqual([1, 2], [1, 2, 3]))
    assert_true(utils.IsEqual([1, 2, 3], [1, 2]))
    assert_false(utils.IsEqual([1, 3], [1, 2, 3]))
enddef

# --- Test: IsLess with equal elements ---
def Test_is_less_equal_elements()
    assert_false(utils.IsLess([1, 2], [1, 2]))
    assert_false(utils.IsGreater([1, 2], [1, 2]))
    assert_true(utils.IsEqual([1, 2], [1, 2]))
enddef

# --- Test: IsLess single element ---
def Test_is_less_single_element()
    assert_true(utils.IsLess([1], [2]))
    assert_false(utils.IsLess([2], [1]))
enddef

# --- Test: IsGreater single element ---
def Test_is_greater_single_element()
    assert_true(utils.IsGreater([2], [1]))
    assert_false(utils.IsGreater([1], [2]))
enddef

# --- Test: IsEqual single element ---
def Test_is_equal_single_element()
    assert_true(utils.IsEqual([1], [1]))
    assert_false(utils.IsEqual([1], [2]))
enddef

# --- Test: IsLess with zeros ---
def Test_is_less_with_zeros()
    assert_true(utils.IsLess([0, 1], [0, 2]))
    assert_false(utils.IsLess([0, 2], [0, 1]))
enddef

# --- Test: IsGreater with zeros ---
def Test_is_greater_with_zeros()
    assert_true(utils.IsGreater([0, 2], [0, 1]))
    assert_false(utils.IsGreater([0, 1], [0, 2]))
enddef

# --- Run all tests ---
Test_is_less_basic()
Test_is_less_different_length()
Test_is_greater_basic()
Test_is_equal_basic()
Test_is_equal_different_length()
Test_is_less_equal_elements()
Test_is_less_single_element()
Test_is_greater_single_element()
Test_is_equal_single_element()
Test_is_less_with_zeros()
Test_is_greater_with_zeros()

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-comparison: All tests passed'
    quitall!
endif
