vim9script

source ../init.vim
import autoload '../../autoload/mplus/quote.vim' as quote

# --- Test: SetQuoteBlock single line ---
def Test_set_quote_single()
    :%delete _
    setline(1, 'Hello world')
    quote.SetQuoteBlock(1, 1)
    assert_equal('> Hello world', getline(1))
enddef

# --- Test: SetQuoteBlock multiple lines ---
def Test_set_quote_multiple()
    :%delete _
    setline(1, ['Line one', 'Line two', 'Line three'])
    quote.SetQuoteBlock(1, 3)
    assert_equal('> Line one', getline(1))
    assert_equal('> Line two', getline(2))
    assert_equal('> Line three', getline(3))
enddef

# --- Test: SetQuoteBlock with CJK content ---
def Test_set_quote_cjk()
    :%delete _
    setline(1, ['中文内容', '更多中文', '混合 text'])
    quote.SetQuoteBlock(1, 3)
    assert_equal('> 中文内容', getline(1))
    assert_equal('> 更多中文', getline(2))
    assert_equal('> 混合 text', getline(3))
enddef

# --- Test: SetQuoteBlock empty lines ---
def Test_set_quote_empty_lines()
    :%delete _
    setline(1, ['Line one', '', 'Line three'])
    quote.SetQuoteBlock(1, 3)
    assert_equal('> Line one', getline(1))
    assert_equal('> ', getline(2))
    assert_equal('> Line three', getline(3))
enddef

# --- Test: SetQuoteBlock partial range ---
def Test_set_quote_partial_range()
    :%delete _
    setline(1, ['Before', 'Target one', 'Target two', 'After'])
    quote.SetQuoteBlock(2, 3)
    assert_equal('Before', getline(1))
    assert_equal('> Target one', getline(2))
    assert_equal('> Target two', getline(3))
    assert_equal('After', getline(4))
enddef

# --- Test: UnsetQuoteBlock single line ---
def Test_unset_quote_single()
    :%delete _
    setline(1, '> Quoted text')
    quote.UnsetQuoteBlock(1, 1)
    assert_equal('Quoted text', getline(1))
enddef

# --- Test: UnsetQuoteBlock multiple lines ---
def Test_unset_quote_multiple()
    :%delete _
    setline(1, ['> Line one', '> Line two', '> Line three'])
    quote.UnsetQuoteBlock(1, 3)
    assert_equal('Line one', getline(1))
    assert_equal('Line two', getline(2))
    assert_equal('Line three', getline(3))
enddef

# --- Test: UnsetQuoteBlock expands upward ---
def Test_unset_quote_expand_up()
    :%delete _
    setline(1, ['> Start quote', '> Middle quote', '> End quote', 'Not quoted'])
    # Select only middle line, should expand up to start
    quote.UnsetQuoteBlock(2, 2)
    assert_equal('Start quote', getline(1))
    assert_equal('Middle quote', getline(2))
    assert_equal('End quote', getline(3))
    assert_equal('Not quoted', getline(4))
enddef

# --- Test: UnsetQuoteBlock expands downward ---
def Test_unset_quote_expand_down()
    :%delete _
    setline(1, ['Not quoted', '> Start quote', '> Middle quote', '> End quote'])
    # Select only middle line, should expand down to end
    quote.UnsetQuoteBlock(2, 2)
    assert_equal('Not quoted', getline(1))
    assert_equal('Start quote', getline(2))
    assert_equal('Middle quote', getline(3))
    assert_equal('End quote', getline(4))
enddef

# --- Test: UnsetQuoteBlock expands both directions ---
def Test_unset_quote_expand_both()
    :%delete _
    setline(1, ['Before', '> Quote start', '> Quote middle', '> Quote end', 'After'])
    # Select middle line, should expand both up and down
    quote.UnsetQuoteBlock(3, 3)
    assert_equal('Before', getline(1))
    assert_equal('Quote start', getline(2))
    assert_equal('Quote middle', getline(3))
    assert_equal('Quote end', getline(4))
    assert_equal('After', getline(5))
enddef

# --- Test: UnsetQuoteBlock with CJK content ---
def Test_unset_quote_cjk()
    :%delete _
    setline(1, ['> 中文引用', '> 更多中文'])
    quote.UnsetQuoteBlock(1, 2)
    assert_equal('中文引用', getline(1))
    assert_equal('更多中文', getline(2))
enddef

# --- Test: UnsetQuoteBlock with varying quote formats ---
def Test_unset_quote_varying_formats()
    :%delete _
    setline(1, ['> Normal quote', '>  Extra space quote', '>No space quote'])
    quote.UnsetQuoteBlock(1, 3)
    assert_equal('Normal quote', getline(1))
    assert_equal('Extra space quote', getline(2))
    # '>No space quote' doesn't match '^\s*>\s' pattern, so it won't be expanded
    # But since we're explicitly selecting 1-3, it will still be processed
    assert_equal('No space quote', getline(3))
enddef

# --- Test: UnsetQuoteBlock non-quote lines (no change) ---
def Test_unset_quote_non_quote_lines()
    :%delete _
    setline(1, ['Plain text', 'More text', 'Even more'])
    quote.UnsetQuoteBlock(1, 3)
    # No lines match '^\s*>\s', so no expansion happens
    # But the selected lines are still processed by the loop
    assert_equal('Plain text', getline(1))
    assert_equal('More text', getline(2))
    assert_equal('Even more', getline(3))
enddef

# --- Test: ToggleQuoteBlock set (no syntax) ---
def Test_toggle_quote_set()
    :%delete _
    setline(1, ['Plain text', 'More text'])
    # Without syntax, ToggleQuoteBlock checks regex only
    # Since lines don't start with >, it should call SetQuoteBlock
    quote.ToggleQuoteBlock(1, 2)
    assert_equal('> Plain text', getline(1))
    assert_equal('> More text', getline(2))
enddef

# --- Test: ToggleQuoteBlock unset (no syntax) ---
def Test_toggle_quote_unset()
    :%delete _
    setline(1, ['> Quoted one', '> Quoted two'])
    # All lines match '^\s*>\s', so it should call UnsetQuoteBlock
    quote.ToggleQuoteBlock(1, 2)
    assert_equal('Quoted one', getline(1))
    assert_equal('Quoted two', getline(2))
enddef

# --- Test: ToggleQuoteBlock mixed (set) ---
def Test_toggle_quote_mixed()
    :%delete _
    setline(1, ['> Quoted', 'Not quoted'])
    # Not all lines are quoted, so it should call SetQuoteBlock
    quote.ToggleQuoteBlock(1, 2)
    assert_equal('> > Quoted', getline(1))
    assert_equal('> Not quoted', getline(2))
enddef

# --- Test: SetQuoteBlock at end of file ---
def Test_set_quote_at_eof()
    :%delete _
    setline(1, ['Before', 'Target'])
    quote.SetQuoteBlock(2, 2)
    assert_equal('Before', getline(1))
    assert_equal('> Target', getline(2))
enddef

# --- Test: UnsetQuoteBlock at start of file ---
def Test_unset_quote_at_bof()
    :%delete _
    setline(1, ['> Target', 'After'])
    quote.UnsetQuoteBlock(1, 1)
    assert_equal('Target', getline(1))
    assert_equal('After', getline(2))
enddef

# --- Run all tests ---
Test_set_quote_single()
Test_set_quote_multiple()
Test_set_quote_cjk()
Test_set_quote_empty_lines()
Test_set_quote_partial_range()
Test_unset_quote_single()
Test_unset_quote_multiple()
Test_unset_quote_expand_up()
Test_unset_quote_expand_down()
Test_unset_quote_expand_both()
Test_unset_quote_cjk()
Test_unset_quote_varying_formats()
Test_unset_quote_non_quote_lines()
Test_toggle_quote_set()
Test_toggle_quote_unset()
Test_toggle_quote_mixed()
Test_set_quote_at_eof()
Test_unset_quote_at_bof()

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-quoteblock: All tests passed'
    quitall!
endif
