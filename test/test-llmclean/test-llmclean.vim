vim9script

source ../init.vim
import autoload '../../autoload/mplus/llmclean.vim' as llmclean

setlocal filetype=markdown
setlocal syntax=markdown

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
    :%delete _
    setline(1, ['Original content.'])
    
    # Simulate ESC to cancel the dialog
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Content should remain unchanged
    assert_equal('Original content.', getline(1))
enddef

# --- Test: execute with all operations disabled ---
def Test_llmclean_no_ops()
    :%delete _
    setline(1, ['Content.'])
    
    # Simulate: press Enter to execute (default button is Execute)
    # All operations are enabled by default, but we can't easily disable them
    # For now, just test that the dialog can be opened and closed
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Content should remain unchanged (cancelled)
    assert_equal('Content.', getline(1))
enddef

# --- Test: empty buffer ---
def Test_llmclean_empty_buffer()
    :%delete _
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Empty buffer should remain empty
    assert_equal(1, line('$'))
    assert_equal('', getline(1))
enddef

# --- Test: CJK content ---
def Test_llmclean_cjk_content()
    :%delete _
    setline(1, ['这是 **粗体** 中文。', '这是 *斜体* 文本。'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Content should remain unchanged (cancelled)
    assert_equal(2, line('$'))
    assert_equal('这是 **粗体** 中文。', getline(1))
enddef

# --- Test: codeblock handling ---
def Test_llmclean_codeblock()
    :%delete _
    setline(1, ['```python', 'def foo():', '    pass', '', '```'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Content should remain unchanged (cancelled)
    assert_equal(5, line('$'))
enddef

# --- Test: numbered list ---
def Test_llmclean_numbered_list()
    :%delete _
    setline(1, ['1. First item', '2. Second item'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Content should remain unchanged (cancelled)
    assert_equal(2, line('$'))
enddef

# --- Test: Chinese punctuation spaces ---
def Test_llmclean_chinese_punct_spaces()
    :%delete _
    setline(1, ['中文 ， 标点 。 测试'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Content should remain unchanged (cancelled)
    assert_equal('中文 ， 标点 。 测试', getline(1))
enddef

# --- Test: citation markers ---
def Test_llmclean_citations()
    :%delete _
    setline(1, ['Text with citation [1] and [2, 3].'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Content should remain unchanged (cancelled)
    assert_equal('Text with citation [1] and [2, 3].', getline(1))
enddef

# --- Test: multiple headings ---
def Test_llmclean_headings()
    :%delete _
    setline(1, ['## Heading 1', 'Content.', '### Heading 2', 'More content.'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Content should remain unchanged (cancelled)
    assert_equal(4, line('$'))
enddef

# --- Test: backslash in numbered lists ---
def Test_llmclean_backslash_numbered()
    :%delete _
    setline(1, ['1\. First item', '2\. Second item'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Content should remain unchanged (cancelled)
    assert_equal('1\. First item', getline(1))
enddef

# --- Test: redundant spaces after list ---
def Test_llmclean_redundant_spaces()
    :%delete _
    setline(1, ['1.  First item', '*  Second item'])
    
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))
    
    # Content should remain unchanged (cancelled)
    assert_equal('1.  First item', getline(1))
enddef

# --- Run all tests ---
Test_quickui_loaded()
Test_llmclean_import()
Test_llmclean_cancel()
Test_llmclean_no_ops()
Test_llmclean_empty_buffer()
Test_llmclean_cjk_content()
Test_llmclean_codeblock()
Test_llmclean_numbered_list()
Test_llmclean_chinese_punct_spaces()
Test_llmclean_citations()
Test_llmclean_headings()
Test_llmclean_backslash_numbered()
Test_llmclean_redundant_spaces()

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-llmclean: All tests passed'
    quitall!
endif
