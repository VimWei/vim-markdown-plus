" MarkdownLinkConceal ----------------------------------------------------{{{1
" 自动隐藏 markdown 链接
" src: https://github.com/jakewvincent/mkdnflow.nvim/commits/main/lua/mkdnflow/conceal.lua
" 解决Mistook todo checkbox as markdown link，要将修订版放在 ~vimfiles/syntax/markdown.vim
" src: https://github.com/tpope/vim-markdown/issues/212

augroup MarkdownLinkConceal
    autocmd!
    autocmd FileType markdown
        \ syn region markdownLink matchgroup=markdownLinkDelimiter
        \ start="(" end=")" contains=markdownUrl keepend contained conceal
    autocmd FileType markdown
        \ syn region markdownLinkText matchgroup=markdownLinkTextDelimiter
        \ start="!\=\[\%(\_[^][]*\%(\[\_[^][]*\]\_[^][]*\)*]\%([[(]\)\)\@="
        \ end="\]\%([[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite
        \ contains=@markdownInline,markdownLineStart concealends
augroup END