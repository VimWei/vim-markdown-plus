vim9script

source ../init.vim
import autoload '../../autoload/mplus/constants.vim' as constants

def Test_text_styles_dict_structure()
    var expected_keys = ['markdownCode', 'markdownItalic', 'markdownItalicU',
        'markdownBold', 'markdownBoldU', 'markdownStrike', 'markdownMark',
        'markdownLinkText', 'markdownUnderline']

    for key in expected_keys
        assert_true(has_key(constants.TEXT_STYLES_DICT, key), $'Missing key: {key}')
    endfor

    assert_equal(len(expected_keys), len(constants.TEXT_STYLES_DICT))

    for [key, entry] in constants.TEXT_STYLES_DICT->items()
        for field in ['open_delim', 'close_delim', 'open_regex', 'close_regex']
            assert_true(has_key(entry, field), $'{key}: missing {field}')
            assert_true(type(entry[field]) == v:t_string, $'{key}: {field} not a string')
            assert_true(len(entry[field]) > 0, $'{key}: empty {field}')
        endfor
    endfor
enddef

def Test_text_styles_dict_delimiters_match_regex()
    var open_tests = {
        markdownCode: '`x',
        markdownItalic: '*x',
        markdownItalicU: '_x',
        markdownBold: '**x',
        markdownBoldU: '__x',
        markdownStrike: '~~x',
        markdownMark: '==x',
        markdownLinkText: '[text](https://example.com)',
        markdownUnderline: '<u>x',
    }

    var close_tests = {
        markdownCode: 'x`',
        markdownItalic: 'x*',
        markdownItalicU: 'x_',
        markdownBold: 'x**',
        markdownBoldU: 'x__',
        markdownStrike: 'x~~',
        markdownMark: 'x==',
        markdownLinkText: '[text](https://example.com)',
        markdownUnderline: 'x</u>',
    }

    for [key, entry] in constants.TEXT_STYLES_DICT->items()
        var open_str = open_tests[key]
        var close_str = close_tests[key]
        assert_true(match(open_str, entry.open_regex) >= 0,
            $'{key}: open_delim not matched by open_regex')
        assert_true(match(close_str, entry.close_regex) >= 0,
            $'{key}: close_delim not matched by close_regex')
    endfor
enddef

def Test_codeblock_dict()
    assert_true(has_key(constants.CODEBLOCK_OPEN_DICT, '```'))
    assert_true(has_key(constants.CODEBLOCK_CLOSE_DICT, '```'))

    assert_equal('^```', constants.CODEBLOCK_OPEN_DICT['```'])
    assert_equal('^```$', constants.CODEBLOCK_CLOSE_DICT['```'])

    assert_true(match('```python', constants.CODEBLOCK_OPEN_DICT['```']) >= 0)
    assert_true(match('```', constants.CODEBLOCK_CLOSE_DICT['```']) >= 0)
    assert_equal(-1, match('```python', constants.CODEBLOCK_CLOSE_DICT['```']))

    assert_true(has_key(constants.QUOTEBLOCK_OPEN_DICT, '> '))
    assert_true(has_key(constants.QUOTEBLOCK_CLOSE_DICT, '> '))
    assert_true(match('> some quote', constants.QUOTEBLOCK_OPEN_DICT['> ']) >= 0)
enddef

def Test_url_prefixes()
    assert_true(type(constants.URL_PREFIXES) == v:t_list)
    assert_true(len(constants.URL_PREFIXES) > 0)

    var expected = ['https://', 'http://', 'ftp://', 'ftps://',
        'sftp://', 'telnet://', 'file://']
    for prefix in expected
        assert_true(index(constants.URL_PREFIXES, prefix) >= 0,
            $'Missing URL prefix: {prefix}')
    endfor

    for prefix in constants.URL_PREFIXES
        assert_true(prefix =~ '://', $'URL prefix missing ://: {prefix}')
    endfor
enddef

Test_text_styles_dict_structure()
Test_text_styles_dict_delimiters_match_regex()
Test_codeblock_dict()
Test_url_prefixes()

if len(v:errors) > 0
    writefile(v:errors, 'test-errors.txt')
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-constants: All tests passed'
    quitall!
endif
