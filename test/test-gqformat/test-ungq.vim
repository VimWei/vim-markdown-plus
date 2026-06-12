vim9script

source ../init.vim

# --- Test: single paragraph merge ---
def Test_ungq_single_paragraph()
    setline(1, ['This is a', 'single paragraph', 'that spans multiple', 'lines.'])
    
    call mplus#gqformat#UngqFormat(1, 4)
    
    assert_equal(1, line('$'))
    assert_equal('This is a single paragraph that spans multiple lines.', getline(1))
enddef

# --- Test: multiple paragraphs ---
def Test_ungq_multiple_paragraphs()
    setline(1, ['First paragraph', 'line one.', '', 'Second paragraph', 'line two.'])
    
    call mplus#gqformat#UngqFormat(1, 5)
    
    assert_equal(3, line('$'))
    assert_equal('First paragraph line one.', getline(1))
    assert_equal('', getline(2))
    assert_equal('Second paragraph line two.', getline(3))
enddef

# --- Test: list item merge ---
def Test_ungq_list_item()
    setline(1, ['- This is a list', 'item that continues', 'on multiple lines.'])
    
    call mplus#gqformat#UngqFormat(1, 3)
    
    assert_equal(1, line('$'))
    assert_equal('- This is a list item that continues on multiple lines.', getline(1))
enddef

# --- Test: multiple list items ---
def Test_ungq_multiple_list_items()
    setline(1, ['- First item', 'continuation.', '- Second item', 'continuation.'])
    
    call mplus#gqformat#UngqFormat(1, 4)
    
    assert_equal(2, line('$'))
    assert_equal('- First item continuation.', getline(1))
    assert_equal('- Second item continuation.', getline(2))
enddef

# --- Test: CJK no space ---
def Test_ungq_cjk_no_space()
    setline(1, ['这是一个', '中文段落', '测试。'])
    
    call mplus#gqformat#UngqFormat(1, 3)
    
    assert_equal(1, line('$'))
    assert_equal('这是一个中文段落测试。', getline(1))
enddef

# --- Test: ASCII space ---
def Test_ungq_ascii_space()
    setline(1, ['Hello world', 'this is a test', 'of ASCII text.'])
    
    call mplus#gqformat#UngqFormat(1, 3)
    
    assert_equal(1, line('$'))
    assert_equal('Hello world this is a test of ASCII text.', getline(1))
enddef

# --- Test: mixed CJK and ASCII ---
def Test_ungq_mixed_cjk_ascii()
    setline(1, ['这是中文', 'and this is English', '混合在一起。'])
    
    call mplus#gqformat#UngqFormat(1, 3)
    
    assert_equal(1, line('$'))
    assert_match('这是中文 and this is English 混合在一起。', getline(1))
enddef

# --- Test: full buffer range ---
def Test_ungq_full_buffer()
    setline(1, ['Full buffer', 'test content.', '', 'Second paragraph.'])
    
    call mplus#gqformat#UngqFormat(1, line('$'))
    
    assert_equal(3, line('$'))
    assert_equal('Full buffer test content.', getline(1))
    assert_equal('', getline(2))
    assert_equal('Second paragraph.', getline(3))
enddef

# --- Test: partial buffer range ---
def Test_ungq_partial_buffer()
    setline(1, ['Before range', '', 'Target paragraph', 'line one.', 'line two.', '', 'After range'])
    
    call mplus#gqformat#UngqFormat(3, 5)
    
    assert_equal(5, line('$'))
    assert_equal('Before range', getline(1))
    assert_equal('', getline(2))
    assert_equal('Target paragraph line one. line two.', getline(3))
    assert_equal('', getline(4))
    assert_equal('After range', getline(5))
enddef

# --- Test: numbered list ---
def Test_ungq_numbered_list()
    setline(1, ['1. First point', 'with details.', '2. Second point', 'more details.'])
    
    call mplus#gqformat#UngqFormat(1, 4)
    
    assert_equal(2, line('$'))
    assert_equal('1. First point with details.', getline(1))
    assert_equal('2. Second point more details.', getline(2))
enddef

# --- Test: alpha list ---
def Test_ungq_alpha_list()
    setline(1, ['a. First option', 'description.', 'b. Second option', 'description.'])
    
    call mplus#gqformat#UngqFormat(1, 4)
    
    assert_equal(2, line('$'))
    assert_equal('a. First option description.', getline(1))
    assert_equal('b. Second option description.', getline(2))
enddef

# --- Test: star list ---
def Test_ungq_star_list()
    setline(1, ['* Star item', 'continuation.'])
    
    call mplus#gqformat#UngqFormat(1, 2)
    
    assert_equal(1, line('$'))
    assert_equal('* Star item continuation.', getline(1))
enddef

# --- Test: hash list ---
def Test_ungq_hash_list()
    setline(1, ['# Hash item', 'continuation.'])
    
    call mplus#gqformat#UngqFormat(1, 2)
    
    assert_equal(1, line('$'))
    assert_equal('# Hash item continuation.', getline(1))
enddef

# --- Test: CJK punctuation no space ---
def Test_ungq_cjk_punctuation()
    setline(1, ['第一句，', '第二句。', '第三句！'])
    
    call mplus#gqformat#UngqFormat(1, 3)
    
    assert_equal(1, line('$'))
    assert_equal('第一句，第二句。第三句！', getline(1))
enddef

# --- Test: paragraph followed by list ---
def Test_ungq_paragraph_then_list()
    setline(1, ['Intro paragraph', 'line one.', '- List item', 'continuation.'])
    
    call mplus#gqformat#UngqFormat(1, 4)
    
    assert_equal(3, line('$'))
    assert_equal('Intro paragraph line one.', getline(1))
    assert_equal('', getline(2))
    assert_equal('- List item continuation.', getline(3))
enddef

# --- Run all tests ---
g:RunTestInBuffer(function('Test_ungq_single_paragraph'))
g:RunTestInBuffer(function('Test_ungq_multiple_paragraphs'))
g:RunTestInBuffer(function('Test_ungq_list_item'))
g:RunTestInBuffer(function('Test_ungq_multiple_list_items'))
g:RunTestInBuffer(function('Test_ungq_cjk_no_space'))
g:RunTestInBuffer(function('Test_ungq_ascii_space'))
g:RunTestInBuffer(function('Test_ungq_mixed_cjk_ascii'))
g:RunTestInBuffer(function('Test_ungq_full_buffer'))
g:RunTestInBuffer(function('Test_ungq_partial_buffer'))
g:RunTestInBuffer(function('Test_ungq_numbered_list'))
g:RunTestInBuffer(function('Test_ungq_alpha_list'))
g:RunTestInBuffer(function('Test_ungq_star_list'))
g:RunTestInBuffer(function('Test_ungq_hash_list'))
g:RunTestInBuffer(function('Test_ungq_cjk_punctuation'))
g:RunTestInBuffer(function('Test_ungq_paragraph_then_list'))

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-ungq: All tests passed'
    quitall!
endif
