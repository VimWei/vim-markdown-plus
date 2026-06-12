vim9script

source ../init.vim
import autoload '../../autoload/mplus/llmclean.vim' as llmclean

# --- Test: quickui is loaded ---
def Test_quickui_loaded()
    assert_true(exists('g:quickui_version'), 'vim-quickui should be loaded')
enddef

# --- Test: llmclean module can be imported ---
def Test_llmclean_import()
    assert_true(exists('*llmclean.Run'), 'llmclean.Run should exist')
enddef

# --- Test: cancel operation (ESC) ---
def Test_llmclean_cancel()
    setline(1, ['Original content.'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal('Original content.', getline(1))
enddef

# --- Test: execute with all operations disabled ---
def Test_llmclean_no_ops()
    setline(1, ['Content.'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal('Content.', getline(1))
enddef

# --- Test: empty buffer ---
def Test_llmclean_empty_buffer()
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal(1, line('$'))
    assert_equal('', getline(1))
enddef

# --- Test: CJK content ---
def Test_llmclean_cjk_content()
    setline(1, ['这是 **粗体** 中文。', '这是 *斜体* 文本。'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal(2, line('$'))
    assert_equal('这是 **粗体** 中文。', getline(1))
enddef

# --- Test: codeblock handling ---
def Test_llmclean_codeblock()
    setline(1, ['```python', 'def foo():', '    pass', '', '```'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal(5, line('$'))
enddef

# --- Test: numbered list ---
def Test_llmclean_numbered_list()
    setline(1, ['1. First item', '2. Second item'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal(2, line('$'))
enddef

# --- Test: Chinese punctuation spaces ---
def Test_llmclean_chinese_punct_spaces()
    setline(1, ['中文 ， 标点 。 测试'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal('中文 ， 标点 。 测试', getline(1))
enddef

# --- Test: citation markers ---
def Test_llmclean_citations()
    setline(1, ['Text with citation [1] and [2, 3].'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal('Text with citation [1] and [2, 3].', getline(1))
enddef

# --- Test: multiple headings ---
def Test_llmclean_headings()
    setline(1, ['## Heading 1', 'Content.', '### Heading 2', 'More content.'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal(4, line('$'))
enddef

# --- Test: backslash in numbered lists ---
def Test_llmclean_backslash_numbered()
    setline(1, ['1\. First item', '2\. Second item'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal('1\. First item', getline(1))
enddef

# --- Test: redundant spaces after list ---
def Test_llmclean_redundant_spaces()
    setline(1, ['1.  First item', '*  Second item'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    assert_equal('1.  First item', getline(1))
enddef

# --- Run all tests ---
g:RunTestInBuffer(function('Test_quickui_loaded'))
g:RunTestInBuffer(function('Test_llmclean_import'))
g:RunTestInBuffer(function('Test_llmclean_cancel'))
g:RunTestInBuffer(function('Test_llmclean_no_ops'))
g:RunTestInBuffer(function('Test_llmclean_empty_buffer'))
g:RunTestInBuffer(function('Test_llmclean_cjk_content'))
g:RunTestInBuffer(function('Test_llmclean_codeblock'))
g:RunTestInBuffer(function('Test_llmclean_numbered_list'))
g:RunTestInBuffer(function('Test_llmclean_chinese_punct_spaces'))
g:RunTestInBuffer(function('Test_llmclean_citations'))
g:RunTestInBuffer(function('Test_llmclean_headings'))
g:RunTestInBuffer(function('Test_llmclean_backslash_numbered'))
g:RunTestInBuffer(function('Test_llmclean_redundant_spaces'))

# --- Report ---
if len(v:errors) > 0
    for err in v:errors
        echomsg err
    endfor
    cquit!
else
    echo 'test-llmclean: All tests passed'
    quitall!
endif
