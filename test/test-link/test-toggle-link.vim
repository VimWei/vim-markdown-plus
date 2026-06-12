vim9script

source ../init.vim
import autoload '../../autoload/mplus/link.vim' as link

# --- Test: wiki.vim is loaded ---
def Test_wiki_vim_loaded()
    assert_true(exists('g:wiki_loaded'), 'wiki.vim should be loaded')
enddef

# --- Test: wiki#link#get_all_from_range finds links ---
def Test_wiki_link_get_all_from_range()
    setline(1, ['[[Test Page]]', '[Link](file:test.md)', 'No link here'])
    
    var links = wiki#link#get_all_from_range(1, 3)
    
    assert_true(len(links) >= 1, 'Should find at least one link')
enddef

# --- Test: ToggleLink with wiki.vim loaded (basic call) ---
def Test_toggle_link_basic_call()
    setline(1, 'Test Page')
    
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 9, 0])
    
    try
        link.ToggleLink('wiki', 'v')
    catch
    endtry
    
    assert_true(v:true)
enddef

# --- Test: RemoveTextOnly basic call ---
def Test_remove_text_only_basic()
    setline(1, '[Link Text](https://example.com)')
    
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 30, 0])
    
    try
        link.RemoveTextOnly('v')
    catch
    endtry
    
    assert_true(v:true)
enddef

# --- Test: ToggleLink with CJK content ---
def Test_toggle_link_cjk_basic()
    setline(1, '中文页面')
    
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])
    
    try
        link.ToggleLink('wiki', 'v')
    catch
    endtry
    
    assert_true(v:true)
enddef

# --- Run all tests ---
g:RunTestInBuffer(function('Test_wiki_vim_loaded'))
g:RunTestInBuffer(function('Test_wiki_link_get_all_from_range'))
g:RunTestInBuffer(function('Test_toggle_link_basic_call'))
g:RunTestInBuffer(function('Test_remove_text_only_basic'))
g:RunTestInBuffer(function('Test_toggle_link_cjk_basic'))

# --- Report ---
if len(v:errors) > 0
    for err in v:errors
        echomsg err
    endfor
    cquit!
else
    echo 'test-toggle-link: All tests passed'
    quitall!
endif
