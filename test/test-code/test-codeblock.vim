vim9script

source ../init.vim
import autoload '../../autoload/mplus/code.vim' as code

# --- Test: UnsetBlock single codeblock ---
def Test_unset_codeblock_single()
    setline(1, ['```python', 'print("hello")', '```'])
    code.UnsetBlock(1, 3)
    assert_equal(['print("hello")'], getline(1, '$'))
enddef

# --- Test: UnsetBlock single codeblock with CJK content ---
def Test_unset_codeblock_cjk()
    setline(1, ['```', '中文内容', '更多中文', '```'])
    code.UnsetBlock(1, 4)
    assert_equal(['中文内容', '更多中文'], getline(1, '$'))
enddef

# --- Test: UnsetBlock multiple codeblocks ---
def Test_unset_codeblock_multiple()
    setline(1, [
        '```python',
        'print("a")',
        '```',
        '',
        '```js',
        'console.log("b")',
        '```'
    ])
    code.UnsetBlock(1, 7)
    assert_equal(['print("a")', '', 'console.log("b")'], getline(1, '$'))
enddef

# --- Test: UnsetBlock partial selection (middle of codeblock) ---
def Test_unset_codeblock_partial_middle()
    setline(1, ['```python', 'line1', 'line2', 'line3', '```'])
    code.UnsetBlock(2, 4)
    assert_equal(['line1', 'line2', 'line3'], getline(1, '$'))
enddef

# --- Test: UnsetBlock selection starts at open wrapper ---
def Test_unset_codeblock_from_open_wrapper()
    setline(1, ['```python', 'code here', '```', 'after'])
    code.UnsetBlock(1, 2)
    assert_equal(['code here', 'after'], getline(1, '$'))
enddef

# --- Test: UnsetBlock selection ends at close wrapper ---
def Test_unset_codeblock_to_close_wrapper()
    setline(1, ['before', '```python', 'code here', '```'])
    code.UnsetBlock(3, 4)
    assert_equal(['before', 'code here'], getline(1, '$'))
enddef

# --- Test: UnsetBlock selection is exactly the close wrapper line ---
def Test_unset_codeblock_close_wrapper_only()
    setline(1, ['```python', 'code here', '```'])
    code.UnsetBlock(3, 3)
    assert_equal(['code here'], getline(1, '$'))
enddef

# --- Test: UnsetBlock selection is exactly the open wrapper line ---
def Test_unset_codeblock_open_wrapper_only()
    setline(1, ['```python', 'code here', '```'])
    code.UnsetBlock(1, 1)
    assert_equal(['code here'], getline(1, '$'))
enddef

# --- Test: UnsetBlock with indented codeblock (wrapper regex requires ^```) ---
def Test_unset_codeblock_indented()
    setline(1, ['  ```python', '  code here', '  ```'])
    code.UnsetBlock(1, 3)
    assert_equal(['  ```python', '  code here', '  ```'], getline(1, '$'))
enddef

# --- Test: UnsetBlock with empty codeblock ---
def Test_unset_codeblock_empty()
    setline(1, ['```', '```'])
enddef

# --- Test: UnsetBlock non-codeblock lines (no change) ---
def Test_unset_codeblock_no_codeblock()
    setline(1, ['plain text', 'more text', 'even more'])
    code.UnsetBlock(1, 3)
    assert_equal(['plain text', 'more text', 'even more'], getline(1, '$'))
enddef

# --- Test: UnsetBlock with CJK in wrapper and content ---
def Test_unset_codeblock_cjk_wrapper()
    setline(1, ['```中文', '内容行', '```'])
    code.UnsetBlock(1, 3)
    assert_equal(['内容行'], getline(1, '$'))
enddef

# --- Test: UnsetBlock overlapping codeblocks in selection ---
def Test_unset_codeblock_overlapping()
    setline(1, [
        '```a',
        'code1',
        '```',
        '```b',
        'code2',
        '```',
        '```c',
        'code3',
        '```'
    ])
    code.UnsetBlock(2, 8)
    assert_equal(['code1', 'code2', 'code3'], getline(1, '$'))
enddef

# --- Test: UnsetBlock codeblock at end of file ---
def Test_unset_codeblock_at_eof()
    setline(1, ['before', '```', 'code', '```'])
    code.UnsetBlock(2, 4)
    assert_equal(['before', 'code'], getline(1, '$'))
enddef

# --- Test: UnsetBlock codeblock at start of file ---
def Test_unset_codeblock_at_bof()
    setline(1, ['```', 'code', '```', 'after'])
    code.UnsetBlock(1, 3)
    assert_equal(['code', 'after'], getline(1, '$'))
enddef

# ========== SetBlock tests (using feedkeys to mock input()) ==========

# --- Test: SetBlock single line with language ---
def Test_set_codeblock_single()
    setline(1, ['before', 'print("hello")', 'after'])
    feedkeys("python\<CR>", 't')
    code.SetBlock(2, 2)
    assert_equal(['before', '```python', 'print("hello")', '```', 'after'], getline(1, '$'))
enddef

# --- Test: SetBlock multiple lines ---
def Test_set_codeblock_multi()
    setline(1, ['top', 'line1', 'line2', 'line3', 'bottom'])
    feedkeys("js\<CR>", 't')
    code.SetBlock(2, 4)
    assert_equal(['top', '```js', 'line1', 'line2', 'line3', '```', 'bottom'], getline(1, '$'))
enddef

# --- Test: SetBlock with CJK content ---
def Test_set_codeblock_cjk()
    setline(1, ['top', '中文内容', '更多中文', 'bottom'])
    feedkeys("python\<CR>", 't')
    code.SetBlock(2, 3)
    assert_equal(['top', '```python', '中文内容', '更多中文', '```', 'bottom'], getline(1, '$'))
enddef

# --- Test: SetBlock with empty language (just press Enter) ---
def Test_set_codeblock_empty_label()
    setline(1, ['top', 'some code', 'bottom'])
    feedkeys("\<CR>", 't')
    code.SetBlock(2, 2)
    assert_equal(['top', '```', 'some code', '```', 'bottom'], getline(1, '$'))
enddef

# --- Test: SetBlock with CJK language label ---
def Test_set_codeblock_cjk_label()
    setline(1, ['top', '内容', 'bottom'])
    feedkeys("中文\<CR>", 't')
    code.SetBlock(2, 2)
    assert_equal(['top', '```中文', '内容', '```', 'bottom'], getline(1, '$'))
enddef

# --- Test: SetBlock partial range in buffer ---
def Test_set_codeblock_partial_range()
    setline(1, ['before', 'code line 1', 'code line 2', 'after'])
    feedkeys("py\<CR>", 't')
    code.SetBlock(2, 3)
    assert_equal(['before', '```py', 'code line 1', 'code line 2', '```', 'after'], getline(1, '$'))
enddef

# ========== ToggleCodeBlock tests ==========

# --- Test: ToggleCodeBlock removes existing codeblock (wrapper detection) ---
def Test_toggle_codeblock_remove()
    setline(1, ['```python', 'print("hello")', '```'])
    code.ToggleCodeBlock(1, 3)
    assert_equal(['print("hello")'], getline(1, '$'))
enddef

# --- Test: ToggleCodeBlock removes CJK codeblock ---
def Test_toggle_codeblock_remove_cjk()
    setline(1, ['```中文', '内容行', '```'])
    code.ToggleCodeBlock(1, 3)
    assert_equal(['内容行'], getline(1, '$'))
enddef

# --- Run all tests ---
g:RunTestInBuffer(function('Test_unset_codeblock_single'))
g:RunTestInBuffer(function('Test_unset_codeblock_cjk'))
g:RunTestInBuffer(function('Test_unset_codeblock_multiple'))
g:RunTestInBuffer(function('Test_unset_codeblock_partial_middle'))
g:RunTestInBuffer(function('Test_unset_codeblock_from_open_wrapper'))
g:RunTestInBuffer(function('Test_unset_codeblock_to_close_wrapper'))
g:RunTestInBuffer(function('Test_unset_codeblock_close_wrapper_only'))
g:RunTestInBuffer(function('Test_unset_codeblock_open_wrapper_only'))
g:RunTestInBuffer(function('Test_unset_codeblock_indented'))
g:RunTestInBuffer(function('Test_unset_codeblock_empty'))
g:RunTestInBuffer(function('Test_unset_codeblock_no_codeblock'))
g:RunTestInBuffer(function('Test_unset_codeblock_cjk_wrapper'))
g:RunTestInBuffer(function('Test_unset_codeblock_overlapping'))
g:RunTestInBuffer(function('Test_unset_codeblock_at_eof'))
g:RunTestInBuffer(function('Test_unset_codeblock_at_bof'))
g:RunTestInBuffer(function('Test_set_codeblock_single'))
g:RunTestInBuffer(function('Test_set_codeblock_multi'))
g:RunTestInBuffer(function('Test_set_codeblock_cjk'))
g:RunTestInBuffer(function('Test_set_codeblock_empty_label'))
g:RunTestInBuffer(function('Test_set_codeblock_cjk_label'))
g:RunTestInBuffer(function('Test_set_codeblock_partial_range'))
g:RunTestInBuffer(function('Test_toggle_codeblock_remove'))
g:RunTestInBuffer(function('Test_toggle_codeblock_remove_cjk'))

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-codeblock: All tests passed'
    quitall!
endif
