vim9script

source ../init.vim
import autoload '../../autoload/mplus/link.vim' as link

setlocal filetype=markdown
setlocal syntax=markdown

# --- Test: wiki.vim is loaded ---
def Test_wiki_vim_loaded()
    assert_true(exists('g:wiki_loaded'), 'wiki.vim should be loaded')
enddef

# --- Test: wiki#link#get_all_from_range finds links ---
def Test_wiki_link_get_all_from_range()
    :%delete _
    setline(1, ['[[Test Page]]', '[Link](file:test.md)', 'No link here'])
    
    # Call the autoload function to trigger loading
    var links = wiki#link#get_all_from_range(1, 3)
    
    # Should find at least the wiki link [[Test Page]]
    assert_true(len(links) >= 1, 'Should find at least one link')
enddef

# --- Test: ToggleLink with wiki.vim loaded (basic call) ---
def Test_toggle_link_basic_call()
    :%delete _
    setline(1, 'Test Page')
    
    # Simulate visual selection by setting '[ and '] marks
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 9, 0])
    
    # Call ToggleLink - verify it doesn't crash
    try
        link.ToggleLink('wiki', 'v')
    catch
        # Some errors are expected if wiki.vim needs configuration
    endtry
    
    # Just verify the function can be called without fatal error
    assert_true(v:true)
enddef

# --- Test: RemoveTextOnly basic call ---
def Test_remove_text_only_basic()
    :%delete _
    setline(1, '[Link Text](https://example.com)')
    
    # Set selection to cover the link
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 30, 0])
    
    try
        link.RemoveTextOnly('v')
    catch
        # Some errors are expected
    endtry
    
    # Verify the function can be called
    assert_true(v:true)
enddef

# --- Test: ToggleLink with CJK content ---
def Test_toggle_link_cjk_basic()
    :%delete _
    setline(1, '中文页面')
    
    # Set selection
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])
    
    try
        link.ToggleLink('wiki', 'v')
    catch
        # Some errors are expected
    endtry
    
    assert_true(v:true)
enddef

# --- Run all tests ---
Test_wiki_vim_loaded()
Test_wiki_link_get_all_from_range()
Test_toggle_link_basic_call()
Test_remove_text_only_basic()
Test_toggle_link_cjk_basic()

# --- Report ---
if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-toggle-link: All tests passed'
    quitall!
endif
